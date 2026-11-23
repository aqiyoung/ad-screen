# 广告屏 · Android 展示端

一台平板 / 电视盒子用的全屏广告屏客户端。当前版本是**前端优先**：循环播放本机上的图片和视频，云端内容源接口已预留，后台上线后无需改播放逻辑。

## 当前能力

- 全屏沉浸播放，屏幕常亮
- 图片按设定秒数轮播，视频播完自动进入下一条，整体循环
- 自动扫描素材文件夹；每 15 秒刷新一次，往文件夹里丢新文件即可上线
- 设置页可改：素材路径、图片停留时长、设备 ID / 名称 / 播放列表 ID、内容源
- 可从本机文件选择器批量导入图片/视频到素材目录
- 多设备结构：每台设备用自己的 `deviceId` 标识，后台上线后按设备下发播放列表

## 拿到 APK

不用在本机构建。推送到 `main` 后，GitHub Actions 会自动跑格式化检查、分析、测试并构建 Release APK：

1. 打开仓库的 **Actions** 页，进入最新一次 `Build Android APK`
2. 在 **Artifacts** 里下载 `ad-screen-release`
3. 解压得到 `app-release.apk`，adb 安装：

```bash
adb install -r app-release.apk
```

打 tag（如 `v0.1.0`）推送后，APK 也会自动挂到对应的 GitHub Release 上。

## 放素材进去

默认素材目录是应用自己的外部存储目录，例如：

```
/sdcard/Android/data/com.aqiyoung.ad_screen/files/media
```

方式一：应用内导入。长按屏幕（或点右下角小齿轮）→「从本机导入图片/视频」。

方式二：adb 直接推送，适合批量更新：

```bash
adb push poster01.jpg /sdcard/Android/data/com.aqiyoung.ad_screen/files/media/
adb push clip01.mp4   /sdcard/Android/data/com.aqiyoung.ad_screen/files/media/
```

支持后缀：图片 `.jpg .jpeg .png .gif .webp .bmp`，视频 `.mp4 .mkv .webm .mov .avi .3gp`。按文件名排序播放。

## 进入设置

播放时长按屏幕任意位置，或点右下角半透明齿轮。设置里还能把素材路径改成其它绝对路径（Android 11+ 访问公共目录可能需要存储权限）。

## 以后接服务端

播放逻辑只依赖 `lib/sources/content_source.dart` 里的 `ContentSource` 抽象类：

- `LocalDirectorySource`：当前实现，读本地文件夹
- `RemoteApiSource`：占位实现，后台就绪后在这里请求接口并缓存素材
- `ContentSourceFactory`：按配置（本地 / 云端）选择实现

设置页已经能填「接口根地址」和「设备 ID / 播放列表 ID」，切到云端源即可。播放器不需要改动。
