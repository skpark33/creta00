import 'package:creta00/common/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:sortedmap/sortedmap.dart';

import 'package:creta00/acc/acc_manager.dart';
//import 'package:creta00/constants/strings.dart';
import '../../model/pages.dart';
import '../../model/models.dart';
import '../../common/undo/undo.dart';

enum PropertyType {
  page,
  acc,
  contents,
}

PageManager? pageManagerHolder;

class PageManager extends ChangeNotifier {
  // factory PageManager.singleton() {
  //   return PageManager();
  // }
  PageManager() {
    load();
  }

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

  bool isAcc() {
    return _propertyType == PropertyType.acc;
  }

  bool isPage() {
    return _propertyType == PropertyType.page;
  }

  bool isContents() {
    return _propertyType == PropertyType.contents;
  }

  int lastWidth = 1920;
  int lastHeight = 1080;

  String _selectedMid = '';

  void load() {
    if (loadBook() == 0) {
      _selectedMid = createPage();
    }
  }

  int loadBook() {
    return 0;
  }

  String createPage() {
    PageModel page = PageModel();
    page.order.set(pageIndex);
    pageMap[page.mid] = page;
    orderMap[page.order.value] = page;
    pageIndex++;
    return page.mid;
  }

  void removePage(String mid) {
    if (pageMap[mid] == null) {
      logHolder.log('removePage($mid) is null', level: 6);
      return;
    }
    logHolder.log('removePage($mid)', level: 6);

    mychangeStack.startTrans();
    for (PageModel model in pageMap.values) {
      if (model.order.value > pageMap[mid]!.order.value) {
        model.order.set(model.order.value - 1);
      }
    }
    pageMap[mid]!.setIsRemoved(true);
    mychangeStack.endTrans();
  }

  changeOrder(int newIndex, int oldIndex) {
    mychangeStack.startTrans();
    orderMap[newIndex]!.order.set(oldIndex);
    orderMap[oldIndex]!.order.set(newIndex);
    mychangeStack.endTrans();
  }

  bool isPageSelected(String mid) {
    logHolder.log('isPageSelected($mid)', level: 6);
    return _selectedMid == mid;
  }

  PageModel? getSelected() {
    if (_selectedMid.isEmpty) {
      return null;
    }
    return pageMap[_selectedMid];
  }

  void setSelectedIndex(BuildContext context, String val) {
    _selectedMid = val;
    logHolder.log('pageId=$val', level: 6);
    accManagerHolder!.showPages(context, val);
    pageManagerHolder!.setAsPage(); //setAsPage contain setState()
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
            //expanded: (selectedModel != null && model.mid == selectedModel.mid),
            children: accNodes));
      }
    }
    return nodes;
  }
}
