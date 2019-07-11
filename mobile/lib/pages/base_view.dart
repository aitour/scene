import 'package:flutter/widgets.dart';
import 'package:mobile/viewmodels/base_model.dart';
import 'package:mobile/locator.dart';
import 'package:provider/provider.dart';

class BaseView<T extends BaseModel> extends StatefulWidget {
  final Widget Function(BuildContext context, T model, Widget child) builder;
  final Function(T) onModelReady;
  final bool disposeModel;

  BaseView({this.builder, this.onModelReady, this.disposeModel=true});

  @override
  State<StatefulWidget> createState() {
    return _BaseViewState<T>();
  }
}

class _BaseViewState<T extends BaseModel> extends State<BaseView<T>> {
  T model = locator<T>();

  @override
  void initState() {
    super.initState();

    if (widget.onModelReady != null) {
      widget.onModelReady(model);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.disposeModel) {
      return ChangeNotifierProvider<T>(
        builder: (context) => model,
        child: Consumer<T>(
          builder: widget.builder,
        ),
      );
    } else {
      return ChangeNotifierProvider<T>.value(
        value: model,
        child: Consumer<T>(builder: widget.builder),
      );
    }
  }
}
