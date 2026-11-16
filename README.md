# 待办清单 · Flutter 移动端应用

一个基于 Flutter（Material 3）实现的待办清单 App，配套单文件高保真 HTML 原型，用于演示移动软件动画课程中的 9.1 / 9.4 / 9.6 / 9.7 四项动画实践。

## 功能

- **待办管理**：新增、编辑、删除、标记完成，按「今天 / 明天」分组展示
- **日历视图**：首页右上角进入日历页，按月翻页，按天查看当天新增了哪些待办
- **统计**：已完成 / 进行中 / 累计项动态计算，点击可查看对应条目列表
- **本地持久化**：全部待办与设置通过 `shared_preferences` 保存在本机
- **个性化**：从相册更换头像、修改姓名
- **偏好设置**：默认分组、深色模式、通知提醒
- **通知**：开启后新增待办会收到系统悬浮通知（Android 13+ 需授予通知权限）

## 动画实践

| 知识点 | 实现位置 | 说明 |
| --- | --- | --- |
| 9.1 AnimationController + Tween + Curve | `todo_app/lib/widgets/animated_counter.dart` | 统计数字从旧值滚动到新值 |
| 9.4 Hero | `home_page.dart` ⇄ `detail_page.dart` | 列表卡片封面与详情头图的共享元素转场 |
| 9.6 AnimatedSwitcher | `home_page.dart` | 剩余待办数量 / 概览文字的切换动画 |
| 9.7 隐式动画家族 | `profile_page.dart` | `AnimatedContainer` / `AnimatedRotation` / `AnimatedDefaultTextStyle` / `AnimatedOpacity` 组合完成「本周完成情况」柱状图的展开收起 |

## 目录结构

```
.
├── todo_app/                    Flutter 应用
│   ├── lib/
│   │   ├── main.dart            应用入口、亮/暗主题
│   │   ├── app_state.dart       全局状态 + 本地持久化（ChangeNotifier）
│   │   ├── notification_service.dart
│   │   ├── models/todo_item.dart
│   │   ├── pages/               home / detail / editor / calendar / stats_list / profile
│   │   └── widgets/             animated_counter / category_art / menu_row
│   ├── android/
│   ├── test/
│   └── pubspec.yaml
├── todo-app.html               单文件高保真交互原型
└── 组件样式参数说明.md          原型的设计参数与组件规范
```

## 运行

要求 Flutter 3.x / Dart 3.x。

```bash
cd todo_app
flutter pub get
flutter run
```

打包安装包：

```bash
flutter build apk --release
```

## 构建说明

仓库针对 Android SDK 36 环境做了两处兼容处理，若你的开发环境 SDK / CMake 完整，可按注释回退：

- `todo_app/android/build.gradle.kts`：将所有插件子工程的 `compileSdk` 统一提升到 36（适配本机仅安装 android-36 的情况）。
- `todo_app/pubspec.yaml` 的 `dependency_overrides`：把 `path_provider_android`、`shared_preferences_android` 固定到不依赖 `jni`（需要 CMake）的版本。

## HTML 原型

`todo-app.html` 可直接用浏览器打开，包含首页、详情、编辑、我的、日历、统计明细与设置对话框。原型数据保存在内存中，刷新后回到示例数据；真正的数据持久化在 Flutter 端。

## 版本

版本 1.0.0

## 下载

安装包见 [Releases](../../releases) 中的 `todo-app-release.apk`。
