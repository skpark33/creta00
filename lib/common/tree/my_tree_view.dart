// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables
//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
//import 'package:provider/provider.dart';
import 'package:creta00/model/pages.dart';
import 'package:creta00/model/contents.dart';
import 'package:creta00/common/util/my_utils.dart';
import 'package:creta00/studio/pages/page_manager.dart';
import 'package:creta00/acc/acc_manager.dart';
import 'package:creta00/acc/acc.dart';
import 'package:creta00/constants/constants.dart';
import 'package:creta00/common/util/logger.dart';

// import 'package:creta00/model/pages.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'TreeView Example',
//       home: TreeView(title: 'TreeView Example'),
//       theme: ThemeData().copyWith(
//         hoverColor: Colors.red.shade100,
//         colorScheme: ThemeData()
//             .colorScheme
//             .copyWith(primary: Colors.red)
//             .copyWith(secondary: Colors.deepPurple),
//       ),
//     );
//   }
// }

class MyTreeView extends StatefulWidget {
  final List<Node> nodes;
  final PageManager pageManager;

  MyTreeView({Key? key, required this.nodes, required this.pageManager}) : super(key: key);

  @override
  _MyTreeViewState createState() => _MyTreeViewState();
}

class _MyTreeViewState extends State<MyTreeView> {
  String _selectedNode = '';
  late TreeViewController _treeViewController;
  bool docsOpen = true;
  bool deepExpanded = true;
  final Map<ExpanderPosition, Widget> expansionPositionOptions = const {
    ExpanderPosition.start: Text('Start'),
    ExpanderPosition.end: Text('End'),
  };
  final Map<ExpanderType, Widget> expansionTypeOptions = {
    ExpanderType.none: Container(),
    ExpanderType.caret: Icon(
      Icons.arrow_drop_down,
      size: 28,
    ),
    ExpanderType.arrow: Icon(Icons.arrow_downward),
    ExpanderType.chevron: Icon(Icons.expand_more),
    ExpanderType.plusMinus: Icon(Icons.add),
  };
  final Map<ExpanderModifier, Widget> expansionModifierOptions = {
    ExpanderModifier.none: ModContainer(ExpanderModifier.none),
    ExpanderModifier.circleFilled: ModContainer(ExpanderModifier.circleFilled),
    ExpanderModifier.circleOutlined: ModContainer(ExpanderModifier.circleOutlined),
    ExpanderModifier.squareFilled: ModContainer(ExpanderModifier.squareFilled),
    ExpanderModifier.squareOutlined: ModContainer(ExpanderModifier.squareOutlined),
  };
  final ExpanderPosition _expanderPosition = ExpanderPosition.start;
  final ExpanderType _expanderType = ExpanderType.caret;
  final ExpanderModifier _expanderModifier = ExpanderModifier.none;
  final bool _allowParentSelect = true;
  final bool _supportParentDoubleTap = true;

  //final ScrollController _scrollController = ScrollController(initialScrollOffset: 0.0);
  Future<String> _getSelectedNode() async {
    PageModel? pageModel = widget.pageManager.getSelected();
    if (pageModel == null) {
      return '';
    }
    ACC? acc = accManagerHolder!.getCurrentACC();
    if (acc == null) {
      return pageModel.mid.toString();
    }

    ContentsModel? model = await acc.accChild.playManager!.getCurrentModel();

    if (model == null) {
      return acc.mid;
    }

    String contentsId = acc.accChild.playManager!.currentIndex.toString().padLeft(2, '0');
    return acc.mid + '/' + contentsPrefix + contentsId + '/' + model.key;
  }

  @override
  void initState() {
    //_selectedNode = widget.pageManager.getSelected()!.id.toString();
    logHolder.log('myTreeView inited : _selectedNode=$_selectedNode');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TreeViewTheme _treeViewTheme = TreeViewTheme(
      expanderTheme: ExpanderThemeData(
        type: _expanderType,
        modifier: _expanderModifier,
        position: _expanderPosition,
        // color: Colors.grey.shade800,
        size: 20,
        color: Colors.blue,
        //color: MyColors.primaryColor,
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w800,
        color: Colors.blue.shade700,
        //color: MyColors.primaryColor,
      ),
      iconTheme: IconThemeData(
        size: 18,
        color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(context).colorScheme,
    );

    return FutureBuilder(
        future: _getSelectedNode(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData == false) {
            //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분을 의미한다.
            return emptyImage();
          }
          if (snapshot.hasError) {
            //error가 발생하게 될 경우 반환하게 되는 부분
            return errMsgWidget(snapshot);
          }
          _selectedNode = snapshot.data!;
          _treeViewController = TreeViewController(
            children: widget.nodes,
            selectedKey: _selectedNode,
          );

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },

            child:
                // Consumer<PageManager>(
                //   builder: (context, pageManager, child) {
                //     logHolder.log('Consumer build PageSwipListState ${pageManager.pageIndex}');

                //     pageManager.reorderMap();
                //     List<PageModel> items = pageManager.orderMap.values.toList();

                //     if (items.isEmpty) {
                //       logHolder.log('item is empty');
                //       return Container();
                //     }
                //     return
                TreeView(
              controller: _treeViewController,
              allowParentSelect: _allowParentSelect,
              supportParentDoubleTap: _supportParentDoubleTap,
              onExpansionChanged: (key, expanded) => _expandNode(key, expanded),
              onNodeTap: (key) {
                debugPrint('Selected: $key');
                setState(() {
                  _selectedNode = key;
                  _treeViewController = _treeViewController.copyWith(selectedKey: key);
                  Node? node = _treeViewController.getNode(key);
                  widget.pageManager.setSelectedIndex(context, node!.data.mid);
                  String mid = '';
                  if (key.contains(accPrefix)) {
                    int pos = accPrefix.length;
                    mid = key.substring(0, pos + 36);
                    logHolder.log('mid=$mid', level: 6);
                    accManagerHolder!.setCurrentMid(mid);
                  }
                  if (mid.isNotEmpty && key.contains(contentsPrefix)) {
                    ACC? acc = accManagerHolder!.getCurrentACC();
                    if (acc != null) {
                      int pos = mid.length + 1 + contentsPrefix.length;
                      int contentsIdx = int.parse(key.substring(pos, pos + 2));
                      debugPrint('selectContents: $contentsIdx');
                      acc.selectContents(context, mid, contentsIdx: contentsIdx);
                    }
                  }
                });
              },
              // onNodeDoubleTap: (key) {
              //   logHolder.log('onNodeDoubleTap', level: 6);
              // },
              // nodeBuilder: (context, node) {
              //   PageModel model = node.data;
              //   String pageNo = (model.pageNo.value + 1).toString().padLeft(2, '0');
              //   String desc = node.data.description.value;
              //   if (desc.isEmpty) {
              //     desc = MyStrings.title + ' $pageNo';
              //   }

              //   return Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              //       IconButton(
              //         padding: EdgeInsets.fromLTRB(12, 0, 12, 0),
              //         iconSize: MySizes.smallIcon,
              //         onPressed: () {
              //           setState(() {
              //             model.isCircle.set(!model.isCircle.value);
              //           });
              //         },
              //         icon: Icon(model.isCircle.value ? Icons.autorenew : Icons.push_pin_outlined),
              //         color: MyColors.icon,
              //       ),
              //       SizedBox(
              //         height: 40,
              //         width: 180,
              //         //color: Colors.red,
              //         child: Row(
              //           crossAxisAlignment: CrossAxisAlignment.center,
              //           children: [
              //             Text(
              //               'Page $pageNo.',
              //               style: MyTextStyles.buttonText,
              //             ),
              //             SizedBox(
              //               width: 118,
              //               child: Text(
              //                 model.description.value.isEmpty
              //                     ? '${MyStrings.title} ${model.id + 1}'
              //                     : model.description.value,
              //                 style: MyTextStyles.description,
              //                 overflow: TextOverflow.ellipsis,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       IconButton(
              //         iconSize: MySizes.smallIcon,
              //         onPressed: () {
              //           setState(() {
              //             widget.pageManager.removePage(model.id);
              //           });
              //         },
              //         icon: Icon(Icons.delete_outline),
              //         color: MyColors.icon,
              //       ),
              //     ]),
              //   );
              // },
              theme: _treeViewTheme,
            ),
            //    },
            //  ),
            // GestureDetector(
            //   onTap: () {
            //     debugPrint('Close Keyboard');
            //     FocusScope.of(context).unfocus();
            //   },
            //   child: Container(
            //     padding: EdgeInsets.only(top: 20),
            //     alignment: Alignment.center,
            //     child: Text(_treeViewController.getNode(_selectedNode) == null
            //         ? ''
            //         : _treeViewController.getNode(_selectedNode)!.label),
            //   ),
            // )
            //],
            //),
            //),
            //)
          );
        });
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: ButtonBar(
//           alignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
//             CupertinoButton(
//               child: Text('Node'),
//               onPressed: () {
//                 setState(() {
//                   _treeViewController = _treeViewController.copyWith(
//                     children: widget.nodes,
//                   );
//                 });
//               },
//             ),
//             CupertinoButton(
//               child: Text('JSON'),
//               onPressed: () {
//                 setState(() {
//                   _treeViewController = _treeViewController.loadJSON(json: US_STATES_JSON);
//                 });
//               },
//             ),
// //            CupertinoButton(
// //              child: Text('Toggle'),
// //              onPressed: _treeViewController.selectedNode != null &&
// //                      _treeViewController.selectedNode.isParent
// //                  ? () {
// //                      setState(() {
// //                        _treeViewController = _treeViewController
// //                            .withToggleNode(_treeViewController.selectedKey);
// //                      });
// //                    }
// //                  : null,
// //            ),
//             CupertinoButton(
//               child: Text('Deep'),
//               onPressed: () {
//                 String deepKey = 'jh1b';
//                 setState(() {
//                   if (deepExpanded == false) {
//                     List<Node> newdata = _treeViewController.expandToNode(deepKey);
//                     _treeViewController = _treeViewController.copyWith(children: newdata);
//                     deepExpanded = true;
//                   } else {
//                     _treeViewController = _treeViewController.withCollapseToNode(deepKey);
//                     deepExpanded = false;
//                   }
//                 });
//               },
//             ),
//             CupertinoButton(
//               child: Text('Edit'),
//               onPressed: () {
//                 TextEditingController editingController =
//                     TextEditingController(text: _treeViewController.selectedNode!.label);
//                 showCupertinoDialog(
//                     context: context,
//                     builder: (context) {
//                       return CupertinoAlertDialog(
//                         title: Text('Edit Label'),
//                         content: Container(
//                           height: 80,
//                           alignment: Alignment.center,
//                           padding: EdgeInsets.all(10),
//                           child: CupertinoTextField(
//                             controller: editingController,
//                             autofocus: true,
//                           ),
//                         ),
//                         actions: <Widget>[
//                           CupertinoDialogAction(
//                             child: Text('Cancel'),
//                             isDestructiveAction: true,
//                             onPressed: () => Navigator.of(context).pop(),
//                           ),
//                           CupertinoDialogAction(
//                             child: Text('Update'),
//                             isDefaultAction: true,
//                             onPressed: () {
//                               if (editingController.text.isNotEmpty) {
//                                 setState(() {
//                                   Node _node = _treeViewController.selectedNode!;
//                                   _treeViewController = _treeViewController.withUpdateNode(
//                                       _treeViewController.selectedKey!,
//                                       _node.copyWith(label: editingController.text));
//                                 });
//                                 debugPrint(editingController.text);
//                               }
//                               Navigator.of(context).pop();
//                             },
//                           ),
//                         ],
//                       );
//                     });
//               },
//             ),
//           ],
//         ),
    //   //),
    // );
  }

  _expandNode(String key, bool expanded) {
    String msg = '${expanded ? "Expanded" : "Collapsed"}: $key';
    debugPrint(msg);
    Node? node = _treeViewController.getNode(key);
    if (node != null) {
      List<Node> updated;
      if (key == 'docs') {
        updated = _treeViewController.updateNode(
            key,
            node.copyWith(
              expanded: expanded,
              icon: expanded ? Icons.folder_open : Icons.folder,
            ));
      } else {
        updated = _treeViewController.updateNode(key, node.copyWith(expanded: expanded));
      }
      setState(() {
        if (key == 'docs') docsOpen = expanded;
        _treeViewController = _treeViewController.copyWith(children: updated);
      });
    }
  }
}

class ModContainer extends StatelessWidget {
  final ExpanderModifier modifier;

  const ModContainer(this.modifier, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _borderWidth = 0;
    BoxShape _shapeBorder = BoxShape.rectangle;
    Color _backColor = Colors.transparent;
    Color _backAltColor = Colors.grey.shade700;
    switch (modifier) {
      case ExpanderModifier.none:
        break;
      case ExpanderModifier.circleFilled:
        _shapeBorder = BoxShape.circle;
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.circleOutlined:
        _borderWidth = 1;
        _shapeBorder = BoxShape.circle;
        break;
      case ExpanderModifier.squareFilled:
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.squareOutlined:
        _borderWidth = 1;
        break;
    }
    return Container(
      decoration: BoxDecoration(
        shape: _shapeBorder,
        border: _borderWidth == 0
            ? null
            : Border.all(
                width: _borderWidth,
                color: _backAltColor,
              ),
        color: _backColor,
      ),
      width: 15,
      height: 15,
    );
  }
}
