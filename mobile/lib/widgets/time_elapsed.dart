import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class TimeElapsedWidget extends StatefulWidget {
  final int totalTicks;
  final VoidCallback onTimeout;
  final Color foreColor, bgColor;
  final int width;

  TimeElapsedWidget(
      {this.totalTicks,
      this.onTimeout,
      this.foreColor,
      this.bgColor,
      this.width});

  @override
  _TimeElapsedWidgetState createState() => _TimeElapsedWidgetState();
}

class _TimeElapsedWidgetState extends State<TimeElapsedWidget> {
  int total = 0;
  int elapsed = 0;
  Timer timer;

  @override
  void initState() {
    super.initState();
    total = widget.totalTicks * 2;
    elapsed = 0;
    timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (++elapsed == total) {
        timer.cancel();
        widget.onTimeout();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: MyPainter(
        totalTicks: total,
        elapsedTicks: elapsed,
        foreColor: this.widget.foreColor,
        bgColor: this.widget.bgColor,
        radius: this.widget.width - 3,
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  Color foreColor;
  Color bgColor;
  int radius;
  int totalTicks;
  int elapsedTicks;

  MyPainter(
      {this.foreColor,
      this.bgColor,
      this.radius,
      this.totalTicks,
      this.elapsedTicks});
  @override
  void paint(Canvas canvas, Size size) {
    double tickRaduis = (2 * math.pi) / totalTicks;

    Paint lineTick = new Paint()
      ..color = foreColor
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    Paint lineElapsedTick = new Paint()
      //..color = foreColor.withAlpha((foreColor.alpha/2).floor())
      ..color = Colors.grey
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

      //canvas.drawLine(Offset.zero, Offset(-radius.toDouble(), radius.toDouble()), lineTick);
    //draw tick lines
    for (int i = 0; i < totalTicks; i++) {
      double elapsedRadius = i * tickRaduis;

      double dx1 = (this.radius - 3) * math.cos(math.pi / 2 - elapsedRadius);
      double dy1 = (this.radius - 3) * math.sin(math.pi / 2 - elapsedRadius);

      double dx2 = this.radius * math.cos(math.pi / 2 - elapsedRadius);
      double dy2 = this.radius * math.sin(math.pi / 2 - elapsedRadius);

      canvas.drawLine(Offset(dx1, -dy1), Offset(dx2, -dy2),
          i <= elapsedTicks ? lineElapsedTick : lineTick);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
