import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Spacing {
  static Widget height(double height) {
    return SizedBox(height: height.h);
  }

  static Widget width(double width) {
    return SizedBox(width: width.w);
  }
}