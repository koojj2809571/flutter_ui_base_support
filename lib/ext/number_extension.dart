part of extenssion_module;

extension NumberUtil on num? {
  /// 非空判断包含null
  bool get empty => this == null;

  /// 数字形式bool值
  bool get bVaule => this != 0;

  ///返回状态栏高度与当前实例相乘的积 status bar height
  double sbh(BuildContext context) =>
      this! * MediaQuery.of(context).padding.top;

  ///返回appbar高度，也就是使用sdk导航栏高度与当前实例相乘的积 app bar height
  double get abh => this! * kToolbarHeight;

  DateTime? get timestamp =>
      this == null ? null : DateTime.fromMillisecondsSinceEpoch(this!.floor());

  /// 输出控制台
  void log({String? tag}) {
    LogUtil.log(tag: tag, text: this);
  }
}
