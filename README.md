# Timetable

将 ColorTimetable 的 Vue 课程表组件迁移为 Flutter Package 的实现，提供与原版一致的视觉与交互，并支持 Android/iOS/Web。

## 功能特性

- 课程表网格布局：按星期×节次渲染课程块，支持冲突去重显示
- 周切换与周概览密度图：横向选择 1..N 周，并显示 5×5 点阵密度
- 课程点击回调：返回课程与当前周信息
- 主题与配色：内置两套色板与暗/亮主题，支持自定义
- 响应式适配：自动根据屏幕尺寸调整列宽与行高

## 安装

在项目的 `pubspec.yaml` 中加入依赖：

```
dependencies:
  timetable:
    path: ../
```

或发布后使用 `flutter pub add timetable`。

## 快速上手

```dart
MaterialApp(
  home: Scaffold(
    body: ColorTimetable(
      courses: [
        TimetableCourse(
          title: '算法设计',
          weekday: 1,
          startPeriod: 1,
          duration: 2,
          weeks: [1, 2, 3],
        ),
      ],
      startOfTerm: DateTime(2024, 9, 2),
      initialWeekIndex: 0,
      referenceDate: DateTime(2024, 9, 2),
      showWeekSelector: true,
      showBuiltinCourseSheet: false,
      onCourseTap: (d) {
        debugPrint('选择: ${d.course.title} 第${d.displayWeek}周');
      },
    ),
  ),
);
```

## API 概览

- `TimetableCourse`：课程模型，`title/teacher/location/weekday/startPeriod/duration/weeks/color`，`endPeriod/occursOnWeek`
- `ColorTimetableTheme`：主题配置，`light/dark` 构造与调色板选择；新增 `inactiveCourseColor/conflictBarColor`
- `TimetableSchedule` 与 `PeriodLabel`：注入一天节次与时间标签，`densityBucketCount` 控制周密度缩略图桶数
- `TimetableController`：可选控制器，`currentWeekIndex/zoom` 与 `setWeekIndex/setZoom`
- `ColorTimetable`：主组件
  - 必填：`courses/startOfTerm/initialWeekIndex/referenceDate`
  - 配置：`showWeekSelector/showBuiltinCourseSheet/showGridLines/showNonCurrentWeekCourses`
  - 样式与行为：`theme/controller/schedule`
  - 回调：`onCourseTap(TimetableCourseTapDetails)`、`onCreateCourse`、`onPaletteTap`、`onWeekChanged`

## 示例与文档

- 示例项目位于 `example/` 目录，包含深浅主题切换与多课程场景
- 更多使用示例与参数说明可参考示例源码

## 测试

- 运行 `flutter test` 执行单元与组件测试

## 兼容性

- 支持 Flutter 最新稳定版，兼容 Android/iOS/Web

## 性能与扩展

- 性能优化
  - 课程块使用 `RepaintBoundary` 隔离重绘
  - 课程颜色分配缓存（按标题稳定配色）
  - 周密度计算缓存（按周与日程配置缓存，变更时自动失效）
  - Builder 与 ListView.builder 避免一次性构建过多元素
- 扩展性
  - 可插拔：`schedule`/`theme`/回调均可替换自定义逻辑
  - 自定义样式：通过 `ColorTimetableTheme.copyWith` 或构造传入自定义颜色
  - 文档与示例：详见 README 与 `example/` 示例工程