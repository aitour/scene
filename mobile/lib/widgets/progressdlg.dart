import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  //子布局
  final Widget child;

  //加载中是否显示
  final double value;

  //进度提醒内容
  final String msg;

  //背景透明度
  final double alpha;

  //字体颜色
  final Color textColor;

  ProgressDialog(
      {Key key,
      @required this.value,
      this.msg,
      this.alpha = 0.6,
      this.textColor = Colors.white,
      @required this.child})
      : assert(child != null),
        assert(value >= 0 && value <= 1),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [];
    widgetList.add(child);
    if (this.value < 1.0) {
      Widget layoutProgress;
      if (msg == null) {
        layoutProgress = Center(
          child: CircularProgressIndicator(value:this.value),
        );
      } else {
        layoutProgress = Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(value:this.value),
                Container(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0),
                  child: Text(
                    msg,
                    style: TextStyle(color: textColor, fontSize: 16.0),
                  ),
                )
              ],
            ),
          ),
        );
      }
      widgetList.add(Opacity(
        opacity: alpha,
        child: new ModalBarrier(color: Colors.black87),
      ));
      widgetList.add(layoutProgress);
    }
    return Stack(
      children: widgetList,
    );
  }
}