//import 'dart:math';
//import 'dart:math';

// ignore_for_file: must_be_immutable

import 'package:creta00/constants/styles.dart';
import 'package:flutter/material.dart';
import '../util/logger.dart';

class HoverButton extends StatefulWidget {
  final void Function() onPressed;
  final void Function() onEnter;
  final void Function() onExit;
  final double width;
  final double height;
  Icon? icon;
  final String text;
  TextStyle textStyle;
  TextStyle hoverTextStyle;
  final double normalSize;
  final double hoverSize;

  IconData? iconData;
  Widget? iconWidget;
  Color? iconColor;
  Color? iconHoverColor;

  bool useIconData = false;
  bool useIconWidget = false;

  bool iconRight = false;
  Color bgColor = Colors.transparent;
  Color borderColor = Colors.transparent;
  double border = 0;
  MainAxisAlignment align = MainAxisAlignment.start;

  HoverButton(
      {Key? key,
      required this.width,
      required this.height,
      required this.onPressed,
      required this.icon,
      required this.onEnter,
      required this.onExit,
      this.text = '',
      this.textStyle = MyTextStyles.body1,
      this.hoverTextStyle = MyTextStyles.body1Hover,
      this.normalSize = 24,
      this.hoverSize = 28,
      this.iconRight = false,
      this.bgColor = Colors.transparent,
      this.borderColor = Colors.transparent,
      this.border = 0,
      this.align = MainAxisAlignment.start})
      : super(key: key);

  HoverButton.withIconData(
      {Key? key,
      required this.width,
      required this.height,
      required this.onPressed,
      required this.iconData,
      required this.iconColor,
      required this.iconHoverColor,
      required this.onEnter,
      required this.onExit,
      this.text = '',
      this.textStyle = MyTextStyles.body1,
      this.hoverTextStyle = MyTextStyles.body1Hover,
      this.normalSize = 24,
      this.hoverSize = 28,
      this.iconRight = false,
      this.bgColor = Colors.transparent,
      this.borderColor = Colors.transparent,
      this.border = 0,
      this.align = MainAxisAlignment.start})
      : useIconData = true,
        super(key: key);

  HoverButton.withIconWidget(
      {Key? key,
      required this.width,
      required this.height,
      required this.onPressed,
      required this.iconWidget,
      required this.onEnter,
      required this.onExit,
      this.text = '',
      this.textStyle = MyTextStyles.body1,
      this.hoverTextStyle = MyTextStyles.body1Hover,
      this.normalSize = 24,
      this.hoverSize = 28,
      this.iconRight = false,
      this.bgColor = Colors.transparent,
      this.borderColor = Colors.transparent,
      this.border = 0,
      this.align = MainAxisAlignment.start})
      : useIconWidget = true,
        super(key: key);

  @override
  _ButtonHoverState createState() =>
      // ignore: no_logic_in_create_state
      _ButtonHoverState(
          // width: width,
          // height: height,
          // onPressed: onPressed,
          // onEnter: onEnter,
          // onExit: onExit,
          // text: text
          );
}

class _ButtonHoverState extends State<HoverButton> {
  // final void Function() onPressed;
  // final void Function() onEnter;
  // final void Function() onExit;
  // final double width;
  // final double height;
  // final String text;

  _ButtonHoverState(
      //{
      // required this.width,
      // required this.height,
      // required this.onPressed,
      // required this.onEnter,
      // required this.onExit,
      // required this.text
      //}
      );

  bool isHover = false;
  bool isClicked = false;
  @override
  Widget build(BuildContext context) {
    double radius = widget.width * 0.05;
    if (radius < 1) {
      radius = 1;
    }
    return GestureDetector(
      onTapDown: (details) {
        if (widget.text.isNotEmpty) {
          logHolder.log('onTabDown');
          setState(() {
            isClicked = true;
          });
          widget.onPressed.call();
        }
      },
      onTapCancel: () {
        logHolder.log('onTapCancel');
        setState(() {
          isClicked = false;
        });
      },
      child: MouseRegion(
        onEnter: (f) {
          setState(() {
            isHover = true;
          });
          widget.onEnter.call();
        },
        onExit: (f) {
          setState(() {
            isHover = false;
            isClicked = false;
          });
          widget.onExit.call();
        },
        child: AnimatedContainer(
          margin: EdgeInsets.symmetric(horizontal: isHover ? 10 : 5),
          //margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: widget.border > 0
                ? Border.all(
                    color: widget.borderColor, width: widget.border, style: BorderStyle.solid)
                : null,
            boxShadow: widget.bgColor != Colors.transparent
                ? [
                    BoxShadow(
                      blurRadius: 2,
                      spreadRadius: 0.5,
                      color: isClicked ? widget.bgColor.withOpacity(0.2) : widget.bgColor,
                    )
                  ]
                : [],
            color: Colors.transparent,
          ),
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          //height: isHover ? height : height * 0.8,
          height: widget.height * 0.8,
          child: addElement(),
        ),
      ),
    );
  }

  Widget _iconButton() {
    return IconButton(
      icon: widget.useIconData
          ? Icon(widget.iconData!, color: isHover ? widget.iconHoverColor : widget.iconColor!)
          : widget.icon!,
      iconSize: isHover ? widget.hoverSize : widget.normalSize,
      padding: const EdgeInsets.all(0),
      onPressed: () {
        setState(() {
          isClicked = true;
        });
        widget.onPressed.call();
      },
    );
  }

  Widget addElement() {
    return Center(
      child: widget.text.isEmpty
          ? widget.useIconWidget
              ? widget.iconWidget!
              : _iconButton()
          : Row(
              mainAxisAlignment: widget.align,
              children: widget.iconRight
                  ? [Text(widget.text, style: widget.textStyle), _iconButton()]
                  : [_iconButton(), Text(widget.text, style: widget.textStyle)],
            ),
    );
  }
}
