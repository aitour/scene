import 'package:flutter/material.dart';
import 'package:mobile/generated/i18n.dart';

class ThresholdSettingView extends StatefulWidget {
  final double threshold;
  final double rangeStart, rangeEnd;

  ThresholdSettingView({this.threshold, this.rangeStart, this.rangeEnd});

  @override
  _ThresholdSettingViewState createState() => _ThresholdSettingViewState();
}

class _ThresholdSettingViewState extends State<ThresholdSettingView> {
  double _sliderValue;

  @override
  void initState() { 
    super.initState();
    _sliderValue = widget.threshold;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(S.of(context).threshold),
        ),
        body: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("${S.of(context).threshold} : ${_sliderValue.toStringAsFixed(2)}"),
                SizedBox(height: 20.0,),
                Slider(
                  activeColor: Colors.indigoAccent,
                  min: widget.rangeStart,
                  max: widget.rangeEnd,
                  //divisions: ((widget.rangeEnd - widget.rangeStart) / 0.01).round(),
                  value: _sliderValue,
                  onChanged: (value) { setState(() {
                    _sliderValue = value;
                  });},
                ),
                SizedBox(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    RaisedButton(
                        child: Text(S.of(context).cancelButtonLabel),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    SizedBox(
                      width: 10.0,
                    ),
                    RaisedButton(
                      child: Text(S.of(context).okButtonLabel),
                      onPressed: () {
                        Navigator.pop(context,
                            _sliderValue);
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
