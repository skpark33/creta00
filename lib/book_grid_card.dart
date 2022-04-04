import 'package:flutter/material.dart';
import 'constants/styles.dart';
import 'model/book.dart';
import 'main_util.dart';

// ignore: must_be_immutable
class BookGridCard extends StatefulWidget {
  final int index;
  final BookModel book;
  final String durationStr;
  final void Function() onTapdown;

  const BookGridCard({
    Key? key,
    required this.index,
    required this.book,
    required this.durationStr,
    required this.onTapdown,
  }) : super(key: key);

  @override
  State<BookGridCard> createState() => _BookGridCardState();
}

class _BookGridCardState extends State<BookGridCard> {
  final double gridWidth = 328;
  final double gridHeight = 210;
  final double gridTitle = 48;
  int hoverIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.transparent, //getColor(index),
        //padding: const EdgeInsets.all(8),
        child: //Container(color: getColor(index)),
            Card(
          shadowColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1.0, color: MyColors.buttonBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          child: GestureDetector(
            onTapDown: (details) => widget.onTapdown(),
            child: MouseRegion(
              onEnter: (event) {},
              onHover: (event) {
                setState(() {
                  hoverIndex = widget.index;
                });
              },
              onExit: (event) {
                setState(() {
                  hoverIndex = -1;
                });
              },
              child: Column(children: [
                SizedBox(
                  // background
                  width: gridWidth,
                  height: gridHeight - gridTitle,
                  child: MainUtil.drawBackground(gridWidth + (hoverIndex == widget.index ? 10 : 0),
                      gridHeight - gridTitle + (hoverIndex == widget.index ? 10 : 0), widget.book),
                ),
                SizedBox(
                  height: gridTitle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(flex: 1, child: Container()),
                      Expanded(
                        flex: 12,
                        child: Text(widget.book.name.value,
                            style: MyTextStyles.cardText1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(flex: 1, child: Container()),
                      Expanded(
                        flex: 6,
                        child: Text(
                          widget.durationStr,
                          style: MyTextStyles.cardText2,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          //height: 200,
        ));
  }
}
