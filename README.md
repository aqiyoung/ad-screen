# AdScreen 广告屏 · Android 展示端

一台平板 / 电视盒子用的全屏广告屏客户端。当前版本是**前端优先**：循环播放导入到应用里的图片和视频，云端内容源接口已预留，后台上线后无需改播放逻辑。

## 当前能力

- 全屏沉浸播放，屏幕常亮
- 横屏、竖屏素材都完整显示（contain，不裁切，留黑边）
- 播放时自动隐藏操作控件；轻触屏幕显示控件，5 秒后自动隐藏；长按屏幕直接进入设置
- 图片按设定秒数轮播，视频播完自动进入下一条，整体循环
- 每 15 秒刷新素材文件夹，导入新文件后自动上线
- **只通过应用内文件选择器导入素材，不申请相册/存储权限，不读取手机上的图片和视频**
- 设置页可改：素材路径、图片停留时长、设备 ID / 名称 / 播放列表 ID、内容源
- 多设备结构：每台设备用自己的 `deviceId` 标识，后台上线后按设备下发播放列表

## 正式信息

- 名称：AdScreen 广告屏
- 包名：`com.threely.ad_screen`
- 版本：1.0.3（versionCode 4）
- 图标：矢量源文件在 `assets/icon/`，已导出到 Android 各密度 mipmap（含自适应图标）

## 拿到安装包

目前**没有发布公开 Release**。推送到 `main` 后，GitHub Actions 会跑格式化检查、分析、测试并构建 APK：

1. 打开仓库 **Actions** → 最新一次 `Build & Release Android`
2. 下载 Artifact `AdScreen-v1.0.3.apk`
3. 解压得到 `AdScreen-v1.0.3.apk`，安装：

```bash
adb install -r AdScreen-v1.0.3.apk
```

需要正式发布时，推送 `v*` tag：CI 会用 GitHub Secrets 里的正式签名密钥构建 APK + AAB 并发布 Release。签名密钥不进仓库。

## 导入素材

长按播放页任意位置（或点右下角小齿轮）→「从本机导入图片/视频」→ 在系统文件选择器里勾选素材。文件会被复制到应用自己的素材目录：

```
/storage/emulated/0/Android/data/com.threely.ad_screen/files/media
```

也可以 `adb push` 到上述目录批量更新。支持后缀：

- 图片：`.jpg .jpeg .png .gif .webp .bmp`
- 视频：`.mp4 .mkv .webm .mov .avi .3gp`

按文件名排序播放。

## 删除素材

长按屏幕（或轻触后点「设置」）进入设置页，「素材文件」区块会列出所有素材，每项右侧有删除按钮；也可以用「清空全部」一次删光。删除后返回播放页会自动刷新。

## 设置

播放时长按屏幕任意位置，或点右下角半透明齿轮。可设置停留秒数、刷新间隔、设备 ID / 名称 / 播放列表 ID、内容源。

## 以后接服务端

播放逻辑只依赖 `lib/sources/content_source.dart` 里的 `ContentSource` 抽象类：

- `LocalDirectorySource`：当前实现，读本地文件夹
- `RemoteApiSource`：占位实现，后台就绪后在这里请求接口并缓存素材
- `ContentSourceFactory`：按配置（本地 / 云端）选择实现

设置页已经能填「接口根地址」和「设备 ID / 播放列表 ID」，切到云端源即可。播放器不需要改动。
