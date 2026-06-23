# iOS 桌面小组件接入手册（P1-7 · v2.5.0）

> 只读「今日日程概览」Widget。Flutter 侧已完成全部桥接代码，本文档是**唯一需在本机 Xcode 操作的一步**：新增 Widget Extension target 并开启 App Group。
> 仓库已准备好全部源码与配置文件，下面按步骤把它们加入工程即可。

## 已就绪的文件

| 文件 | 作用 |
|---|---|
| `lib/services/widget_service.dart` | Flutter 侧桥接，写入今日日程并刷新 Widget（仅 iOS 生效） |
| `ios/Runner/Runner.entitlements` | 主 App 的 App Group 授权 |
| `ios/QianqianWidget/QianqianWidget.swift` | WidgetKit 扩展（TimelineProvider + SwiftUI 只读视图） |
| `ios/QianqianWidget/Info.plist` | 扩展 Info.plist（NSExtensionPointIdentifier = widgetkit-extension） |
| `ios/QianqianWidget/QianqianWidget.entitlements` | 扩展的 App Group 授权 |

约定（双端已一致，勿改动单边）：

- App Group：`group.com.qianqian.qianqianGrowthLogbook`
- 共享 key：`today_schedules`（JSON）/ `today_date` / `today_count`
- iOS Widget kind：`QianqianWidget`

## 操作步骤（Xcode）

1. **打开工程**
   `open ios/Runner.xcworkspace`

2. **新增 Widget Extension target**
   - File ▸ New ▸ Target… ▸ 选择 **Widget Extension**。
   - Product Name 填 **QianqianWidget**（务必与 kind 一致）。
   - 取消勾选 “Include Configuration Intent”（本期为静态只读，不需要 App Intent）。
   - Finish；弹出 “Activate scheme?” 选 **Cancel**（保持 Runner scheme）。

3. **用仓库源码替换自动生成文件**
   - Xcode 自动在 `ios/QianqianWidget/` 生成了模板文件。用本仓库已准备的同名文件覆盖其内容：
     - `QianqianWidget.swift`（整份替换）
     - `Info.plist`（如生成的不同，替换为本仓库版本）
   - 确保 `QianqianWidget.swift` 的 Target Membership 勾选了 **QianqianWidget**（不要勾 Runner）。

4. **开启 App Group（两个 target 都要）**
   - 选中 **Runner** target ▸ Signing & Capabilities ▸ `+ Capability` ▸ **App Groups**
     ▸ 勾选/新增 `group.com.qianqian.qianqianGrowthLogbook`。
     （会生成/更新 `Runner.entitlements`，与本仓库一致即可。）
   - 选中 **QianqianWidget** target ▸ 同样添加 **App Groups** ▸ 勾选同一个 group。
   - 两个 target 的 `Signing` 选择同一 Team（`C372PW5869`）。

5. **确认扩展的 entitlements 路径**
   - QianqianWidget target ▸ Build Settings ▸ `Code Signing Entitlements`
     指向 `QianqianWidget/QianqianWidget.entitlements`（Xcode 通常自动设置）。

6. **pod 安装 & 运行**
   ```bash
   cd ios && pod install && cd ..
   flutter run            # 真机或模拟器
   ```
   - 启动 App 进入任意带日程的页面（首页/日程），`ScheduleProvider.loadSchedules` 会把今日日程写入 App Group 并刷新 Widget。
   - 回到桌面长按 ▸ 添加小组件 ▸ 搜索「芊芊今日」，添加 small/medium/large 任一尺寸即可看到今日日程。

## 验证清单

- [ ] 桌面 Widget 显示今日日期与「N 项」。
- [ ] 列出今日日程：分类色条 + 图标 + 标题 + 时间。
- [ ] 已打卡项显示删除线 + 玫瑰粉对勾，未打卡显示时间。
- [ ] 在 App 内打卡/撤销/增删改日程后，Widget 数据随之更新（可能有数十秒系统刷新延迟）。
- [ ] 今日无安排时显示「今天没有安排，好好休息～」。

## 多机开发 / 构建的签名注意事项（做法 A：自动签名）

场景：**A 电脑做开发，B 电脑构建并上传 App Store**。签名能力绑定 Apple 开发者账号（Team `C372PW5869`），不绑定具体机器，因此可多机协作。Widget 的 target 配置、App Group ID、entitlements 都跟随 git 走，B 电脑 clone 即有；唯一需要在机器间搬运的是 **Distribution 证书的私钥**。

### 一、A 电脑（开发机，做一次）

1. **登录 Apple ID**：Xcode ▸ Settings ▸ Accounts ▸ `+` 登录开发者账号，确认能看到 Team `C372PW5869`。
2. **两个 target 都开自动签名**：分别选中 `Runner` 和 `QianqianWidget` ▸ Signing & Capabilities：
   - 勾选 ✅ **Automatically manage signing**，Team 选 `C372PW5869`。
   - Xcode 会自动注册 App ID、生成 Development 证书与 Profile。
3. **导出 Distribution 证书私钥**（关键，避免 B 电脑另生成新证书）：
   - 若从未发布过，可先生成发布证书：Settings ▸ Accounts ▸ 选中 Team ▸ **Manage Certificates** ▸ 左下 `+` ▸ **Apple Distribution**。
   - 打开「钥匙串访问」▸ 类别「我的证书」▸ 找到 **Apple Distribution: …（C372PW5869）**。
   - 右键 ▸ **导出**，存为 `qianqian_dist.p12`，设导出密码（记好）。
   - 务必展开三角能看到下面挂着一把**私钥**再导出，否则导出的是无私钥的 `.cer`，无效。

### 二、传输

通过 AirDrop / 加密网盘 / U 盘把 `qianqian_dist.p12` 传到 B 电脑。**不要走明文聊天工具**，这是含私钥的发布凭证。

### 三、B 电脑（构建机）

1. **登录同一个 Apple ID**：Xcode ▸ Settings ▸ Accounts ▸ `+` 登录**同一**账号。
2. **导入私钥**：双击 `qianqian_dist.p12` ▸ 输入密码 ▸ 导入「登录」钥匙串。验证：「我的证书」里 **Apple Distribution: …** 下挂着私钥。
3. **拉代码装依赖**：
   ```bash
   git clone <repo> && cd qq_glb
   flutter pub get
   cd ios && pod install && cd ..
   ```
4. **确认签名**：`open ios/Runner.xcworkspace` ▸ 两个 target 勾 ✅ Automatically manage signing、Team 选 `C372PW5869`。私钥已在本机，Xcode 会**复用**同一张 Distribution 证书，不新建。
5. **构建上传**：Product ▸ Archive ▸ Distribute App ▸ App Store Connect。

### 为什么必须导私钥

一个 Apple 账号的 Distribution 证书有数量上限（通常 2~3 张）。B 电脑若没导入私钥，自动签名会**新建**一张，多机来回易撞上限且难管理。导入同一私钥 = 两机共用同一张发布证书，最干净。

## 备注

- 本期不含「桌面快捷打卡」（需 iOS 17+ App Intents），点按 Widget 仅打开 App，已按 v2.5.0 范围裁剪。
- 非 iOS 平台 `WidgetService` 全部 no-op，Android/macOS/单测不受影响。

## 实战排错（v2.5.0 模拟器接入实录）

> 以下是首次用 Xcode 16/26 新建 Widget Extension target 接入时真实踩到的坑与解法，按出现顺序排列。重建 target 或换机时可对照。

### 1. Xcode 自动生成多余模板文件
新建 Widget Extension 后，Xcode 会生成 `QianqianWidgetBundle.swift`、`QianqianWidgetControl.swift`、`QianqianWidgetLiveActivity.swift`，并把 `QianqianWidget.swift` 覆盖成 emoji 示例模板。
- 用仓库版本覆盖 `QianqianWidget.swift`。
- `QianqianWidgetBundle.swift` 精简为只暴露 `QianqianWidget()`（移除 Control/LiveActivity 引用，否则引入 iOS 18 / ActivityKit 依赖）。
- `QianqianWidgetControl.swift` / `QianqianWidgetLiveActivity.swift` 置空（本期不用）。

### 2. 报错 `Embedding a binary doesn't make sense for this target type`
App Extension 不能嵌入二进制。检查 **QianqianWidget** target ▸ General ▸ Frameworks, Libraries, and Embedded Content：把 `WidgetKit.framework` / `SwiftUI.framework` 等设为 **Do Not Embed**；移除任何被加进来的 `Pods_*.framework`。

### 3. 报错 `Cycle inside Runner; building could produce unreliable results`
Flutter + Widget Extension 在 Xcode 16 的经典循环依赖。解法：**Runner ▸ Build Phases，把 `Embed Foundation Extensions` 拖到 `Thin Binary` 之前**（已写进 `project.pbxproj`，git 同步后 B 电脑不会再遇到，除非重建 target）。备选：取消 `Thin Binary` 脚本的 "Based on dependency analysis"。

### 4. `pod install` 报 `Generated.xcconfig must exist`
`flutter clean` 删掉了该文件。顺序改为：先 `flutter pub get` 再 `pod install`（或直接 `flutter run` 自动处理 Pods）。

### 5. 桌面小组件库里搜不到 widget
扩展已正确安装（`Runner.app/PlugIns/` 里有 `.appex`）但系统未索引。**重启模拟器**让 SpringBoard 重新扫描即可：
```bash
xcrun simctl shutdown booted && xcrun simctl boot <UDID> && open -a Simulator
```

### 6. widget 显示但数据不更新（App Group 没打通）
最隐蔽的一坑。entitlements 文件存在、内容正确，但 `CODE_SIGN_ENTITLEMENTS` 没指向它们，导致 App/Widget 签名里都没有 App Group 授权、共享容器不创建。
- 排查：`codesign -d --entitlements :- <app/appex>` 看有无 `application-groups`；`xcrun simctl get_app_container booted <bundleid> group.com.qianqian.qianqianGrowthLogbook` 看容器是否存在。
- 解法：两个 target 的所有 build config 设置 `CODE_SIGN_ENTITLEMENTS` 指向各自 entitlements 文件（`Runner/Runner.entitlements`、`QianqianWidget/QianqianWidget.entitlements`），卸载旧 App 重装。已写进 `project.pbxproj`。
- 真机/上架：自动签名要求 provisioning 含该 App Group，需在两个 target 的 Signing & Capabilities 正式加一次 **App Groups** capability（Xcode 会自动到后台注册）。模拟器不受此限制。
