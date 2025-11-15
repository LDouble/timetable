# 代码风格与约定
- 启用了 `analysis_options.yaml` -> `package:flutter_lints/flutter.yaml`，遵循 Flutter 官方静态检查规则（lowerCamelCase 命名、prefer_const_constructors、避免未使用代码等）
- 提交前使用 `dart format` / `flutter format` 来保证统一格式
- Dart/Flutter 组件应倾向于无状态/有状态 Widget 的清晰拆分，并保持可复用的样式配置（例如自定义主题、颜色常量）
- 由于项目目标是复刻 ColorTimetable，需要在 UI 上保持与原项目一致（配色、圆角、渐变、阴影等）并封装可配置主题