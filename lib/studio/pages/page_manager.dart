import 'package:creta00/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:sortedmap/sortedmap.dart';

import 'package:creta00/acc/acc_manager.dart';
//import 'package:creta00/constants/strings.dart';
import '../../creta_main.dart';
import '../../model/pages.dart';
import '../../model/models.dart';
import '../../model/model_enums.dart';
import '../../common/undo/undo.dart';
//import '../../db/db_actions.dart';

PageManager? pageManagerHolder;

class PageManager extends ChangeNotifier {
  // factory PageManager.singleton() {
  //   return PageManager();
  // }

  int pageIndex = 0;
  Map<String, PageModel> pageMap = <String, PageModel>{};
  SortedMap<int, PageModel> orderMap = SortedMap<int, PageModel>();
  List<Node> nodes = [];

  PropertyType _propertyType = PropertyType.page;
  PropertyType get propertyType => _propertyType;
  void setPropertyType(PropertyType p) {
    _propertyType = p;
  }

  Future<void> setAsAcc() async {
    _propertyType = PropertyType.acc;
    notifyListeners();
  }

  Future<void> setAsPage() async {
    _propertyType = PropertyType.page;
    notifyListeners();
  }

  Future<void> setAsContents() async {
    _propertyType = PropertyType.contents;
    notifyListeners();
  }

  Future<void> setAsBook() async {
    _propertyType = PropertyType.book;
    notifyListeners();
  }

  bool isAcc() {
    return _propertyType == PropertyType.acc;
  }

  bool isPage() {
    return _propertyType == PropertyType.page;
  }

  bool isContents() {
    return _propertyType == PropertyType.contents;
  }

  bool isBook() {
    return _propertyType == PropertyType.book;
  }

  int lastWidth = 1920;
  int lastHeight = 1080;

  String _selectedMid = '';

  void createFirstPage() {
    _selectedMid = createPage();
  }

  String createPage() {
    PageModel page = PageModel(cretaMainHolder!.defaultBook!.mid);
    page.order.set(pageIndex);
    logHolder.log('createPage $pageIndex', level: 5);
    pageMap[page.mid] = page;
    orderMap[page.order.value] = page;
    pageIndex++;
    return page.mid;
  }

  void pushPages(List<PageModel> list) {
    logHolder.log('pushPages $pageIndex', level: 5);
    pageMap.clear();
    orderMap.clear();
    int minOrder = 999999999;
    int maxOrder = 0;
    for (PageModel page in list) {
      logHolder.log('page(${page.order.value}) added', level: 5);
      pageMap[page.mid] = page;
      orderMap[page.order.value] = page;
      if (page.order.value <= minOrder) {
        minOrder = page.order.value;
      }
      if (page.order.value > maxOrder) {
        maxOrder = page.order.value;
      }
      if (page.accPropertyList.isNotEmpty) {
        accManagerHolder!.pushACCs(page);
      }
    }
    pageIndex = maxOrder + 1;
    _selectedMid = orderMap[minOrder] != null ? orderMap[minOrder]!.mid : '';
  }

  void makeCopy(String oldBookMid, String newBookMid) {
    for (PageModel page in pageMap.values) {
      if (page.parentMid.value == oldBookMid) {
        PageModel newPage = page.makeCopy(newBookMid);
        accManagerHolder!.makeCopy(page.mid, newPage.mid);
      }
    }
  }

  void removePage(String mid) {
    if (pageMap[mid] == null) {
      logHolder.log('removePage($mid) is null', level: 5);
      return;
    }
    logHolder.log('removePage($mid)', level: 5);

    mychangeStack.startTrans();
    for (PageModel model in pageMap.values) {
      if (model.order.value > pageMap[mid]!.order.value) {
        model.order.set(model.order.value - 1);
      }
    }
    pageMap[mid]!.isRemoved.set(true);
    mychangeStack.endTrans();
  }

  changeOrder(int newIndex, int oldIndex) {
    logHolder.log('changeOrder($oldIndex --> $newIndex)', level: 5);
    mychangeStack.startTrans();
    orderMap[newIndex]!.order.set(oldIndex);
    orderMap[oldIndex]!.order.set(newIndex);
    mychangeStack.endTrans();
  }

  bool isPageSelected(String mid) {
    logHolder.log('isPageSelected($mid)');
    return _selectedMid == mid;
  }

  PageModel? getSelected() {
    if (_selectedMid.isEmpty) {
      return null;
    }
    return pageMap[_selectedMid];
  }

  Future<void> setSelectedIndex(BuildContext context, String val) async {
    _selectedMid = val;
    pageManagerHolder!.setAsPage(); //setAsPage contain setState()
    PageModel? page = pageManagerHolder!.getSelected();
    if (page != null) {
      await page.waitPageBuild(); // 페이지가 완전히 빌드 될때까지 기둘린다.
      accManagerHolder!.showPages(context, val); // page 가 완전히 노출된 후에 ACC 를 그린다.
    }
  }

  void reorderMap() {
    orderMap.clear();
    for (PageModel model in pageMap.values) {
      if (model.isRemoved.value == false) {
        orderMap[model.order.value] = model;
      }
    }
  }

  void setState() {
    notifyListeners();
  }

  List<Node> toNodes(PageModel? selectedModel) {
    //  Node(
    //       label: 'documents',
    //       key: 'docs',
    //       expanded: docsOpen,
    //       // ignore: dead_code
    //       icon: docsOpen ? Icons.folder_open : Icons.folder,
    //       children: [ ]
    //  );
    for (PageModel model in orderMap.values) {
      if (model.isRemoved.value == false) {
        String pageNo = (model.order.value + 1).toString().padLeft(2, '0');
        String desc = model.getDescription();
        List<Node> accNodes = accManagerHolder!.toNodes(model);
        nodes.add(Node<AbsModel>(
            key: model.mid,
            label: 'Page $pageNo. $desc',
            data: model,
            expanded: (selectedModel != null && model.mid == selectedModel.mid) || model.expanded,
            children: accNodes));
      }
    }
    return nodes;
  }
}
