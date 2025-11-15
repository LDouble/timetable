# 提交前检查
1. `flutter pub get`（如依赖更新）以确保可构建
2. `dart format .`/`flutter format` 格式化所有受影响的 Dart 文件
3. `flutter analyze` 确认通过所有静态检查
4. `flutter test` 运行测试（必要时补充新的 golden/Widget 测试）
5. 若涉及 UI 变更，建议对照 `ColorTimetable-main` 运行 `pnpm run dev:mp-weixin` 以核对视觉一致性
6. 更新 README / CHANGELOG 记录重要功能或配置变更