import 'package:creta00/creta_main.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.transparent, //getColor(index),
        //padding: const EdgeInsets.all(8),
        child: //Container(color: getColor(index)),
            Card(
          shadowColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1.0, color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 8,

          child: Stack(children: [
            Column(children: [
              SizedBox(
                // background
                width: gridWidth,
                height: gridHeight - gridTitle,
                child: MainUtil.drawBackground(gridWidth, gridHeight - gridTitle, widget.book),
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
            HoverWidget(
              width: gridWidth,
              height: gridHeight,
              index: widget.index,
              book: widget.book,
              onTapdown: widget.onTapdown,
            ),
          ]),

          //height: 200,
        ));
  }
}

class HoverWidget extends StatefulWidget {
  final double width;
  final double height;
  final int index;
  final BookModel? book;
  final void Function() onTapdown;
  final double hoverOpacity;
  final double normalOpacity;
  final Widget? hoverWidget;

  const HoverWidget({
    Key? key,
    this.book,
    required this.width,
    required this.height,
    required this.index,
    required this.onTapdown,
    this.hoverOpacity = 0.4,
    this.normalOpacity = 0.0,
    this.hoverWidget,
  }) : super(key: key);

  @override
  State<HoverWidget> createState() => _HoverWidgetState();
}

class _HoverWidgetState extends State<HoverWidget> {
  int hoverIndex = -1;
  // ignore: unused_field

  bool _isClikcked() {
    return widget.book != null && widget.book!.mid == cretaMainHolder!.defaultBook!.mid;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        widget.onTapdown();
        setState(() {});
      },
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
        child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                  (hoverIndex == widget.index) ? widget.hoverOpacity : widget.normalOpacity),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: Border.all(
                  width: _isClikcked() ? 6.0 : 0.0, color: Colors.white, style: BorderStyle.solid),
            ),
            child: (widget.book == null && widget.hoverWidget != null)
                ? widget.hoverWidget!
                : (hoverIndex == widget.index && widget.book != null)
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 50.0),
                        child: Text(
                          widget.book!.description.value,
                          style: MyTextStyles.cardText1,
                        ),
                      )
                    : Container()),
      ),
    );
  }
}
