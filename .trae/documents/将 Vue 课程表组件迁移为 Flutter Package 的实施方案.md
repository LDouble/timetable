## 项目目标
- 将 ColorTimetable-main 中的课程表核心功能完整迁移为一个独立的 Flutter package（Android/iOS/Web）。
- 保持与 Vue 版本一致的视觉风格、交互与布局；支持动态数据加载与更新，具备良好性能与响应式适配。
- 提供完善的 API、示例与测试，遵循 Dart/Flutter 最佳实践并兼容最新稳定版 Flutter。

## 现有 Vue 特性复刻清单
- 周切换与周概览密度图（TimetableAction）：点击/滑动切周、密度点阵展示 1..20 周。
- 课表网格渲染（TimetableContent）：按星期×节次栅格布局课程块，重叠课程分栏与冲突提示。
- 顶部头部（TimetableHeader）：显示当前月/周标题、周内日期并高亮当天。
- 课程点击弹层（CourseActionSheet）：同一时段课程列表弹出层，支持跳转编辑。
- 学期起始日与周序计算：首日设置、当前周索引、当月与周内日期数组计算。
- 主题与暗黑模式：延用两套色板与主题变量，保持视觉一致。

## Flutter Package 架构
- `lib/timetable.dart`：对外入口与导出。
- `lib/src/models.dart`：数据模型（Course/Meeting/WeekSchedule/Weekday/TimeRange）。
- `lib/src/controller.dart`：`TimetableController`（ChangeNotifier）管理当前周、选中态、缩放等。
- `lib/src/theme.dart`：`ThemeExtension<TimetableTheme>` 扩展（背景/网格/文字/选中态/间距/行高）。
- `lib/src/widgets/`：`TimetableView`（顶层）· `TimetableHeader` · `TimetableGrid` · `CourseTile` · `WeekDensityBar`（周概览）。
- `example/`：示例应用展示主视图与多场景用法。
- `test/`：模型/控制器/组件/golden/perf 测试。

## 数据模型与状态
- Course：`id/title/teacher/room/color/meetings[]`。
- Meeting：`weekday/time(分钟)/weeks?`，支持指定周次或全周。
- WeekSchedule：按周过滤 meetings；为网格布局提供查询接口。
- Controller：`currentWeek/zoom/selectedIds` 与 `setWeek/setZoom/toggleSelect/clearSelection` 通知更新。
- 可选状态管理：Provider（默认）或 Riverpod（复杂场景）。

## 组件与交互（1:1 保持）
- 周切换与手势：水平滑动阈值控制，点击密度图定位周；支持“返回本周”。
- 网格与布局：`Stack + Positioned` 按时间/星期计算相对位置，重叠课程分栏与宽度压缩。
- 课程点击：触发 `onCourseTap(course, meeting)`；可扩展长按与拖拽。
- 可定制构建器：`courseTileBuilder/timeLabelBuilder` 插槽等价替换。

## 主题与视觉一致性
- 复刻 Vue 两套色板与主题变量（暗/亮），确保色值、间距、字体一致。
- 提供 `TimetableTheme.copyWith/lerp`，支持动画过渡与自定义品牌色。
- 保留稠密图、网格线、选中边框与周末高亮风格。

## 动画与性能
- 栅格切换/周切换采用 `AnimatedSwitcher/AnimatedPositioned/FadeTransition`，流畅过渡。
- 大数据优化：常量布局缓存、文本测量缓存、避免重建；Web 使用 CanvasKit 验证像素对齐。
- 响应式：`LayoutBuilder/MediaQuery` 按屏幕宽高动态计算列宽与行高，支持旋转与多尺寸。

## 对外 API 设计
- `TimetableView({schedule, controller, startHour, endHour, onCourseTap, timeLabelBuilder, courseTileBuilder})`。
- 工具方法：`scrollToNow()`（可选）、`setWeek(int)`、`setZoom(double)`。
- 模型/主题/控制器均通过 `timetable.dart` 导出，便于集成。

## 示例与文档
- README：安装方法、快速上手、完整参数与回调说明、主题定制指南、常见问题。
- 示例项目：主视图、暗/亮主题切换、重叠课程示例、密度图与手势演示。
- API 文档：dartdoc 生成（pub.dev 友好）。

## 测试与验证
- 单元：`TimeRange.intersects`、`Meeting.inWeek`、重叠分栏算法、控制器通知语义。
- 组件：渲染密度/主题高亮/缩放行为、构建器覆盖。
- Golden：主视图在不同主题/缩放的视觉回归。
- 性能：100+ 课程数据帧时间监控；Web 与移动端一致性。

## 兼容性与 Web 支持
- Flutter 稳定版 SDK 编译通过；不依赖平台通道。
- Android/iOS/Web 三端一致；Web 使用纯 Flutter 渲染（无额外 JS）。

## 里程碑与交付物
- Phase 1：模型与控制器（Dart 数据结构与状态管理）。
- Phase 2：网格/头部/密度图组件与交互（含动画）。
- Phase 3：主题与色板复刻（暗/亮一致）。
- Phase 4：API & README & 示例（dartdoc + example）。
- Phase 5：测试（单元/组件/golden/perf）与优化。
- Phase 6：Web 验证与兼容性收尾（CI 任务）。
- 交付：完整 package 源码、README、示例项目、测试集与报告。

## 注意事项
- 色值与间距以 Vue 版为单一真源；对齐差异将通过截图比对与 golden 测试校验。
- 周密度图与冲突标记严格复刻逻辑；必要时提供扩展开关以支持不同学校排课规则。

请确认以上方案。如果认可，我将按“里程碑”逐步落地实现并提交可运行的 Flutter package。