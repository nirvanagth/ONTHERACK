# ONTHERACK

**5x5 健身记录 App** — 专为 StrongLifts 5x5 训练计划设计。

## 快速开始

### 先装 Xcode

1. 打开 Mac App Store，搜索 "Xcode" 安装（~15GB）
2. 安装完成后打开一次，同意协议，装好 iOS 18 Simulator

### 打开项目

Xcode 16+ 可以直接打开 Package.swift：

```
File > Open... > 选择 ~/Projects/ONTHERACK/Package.swift
```

如果 Xcode 提示 "Do you trust and open this package?" — 选 Trust。

然后选择 iOS Simulator 作为目标设备，按 Cmd+R 运行。

### 或者手动创建项目（备选）

如果 Package.swift 方式不行：

1. Xcode > File > New > Project
2. 选 iOS > App，点 Next
3. Product Name: ONTHERACK，Interface: SwiftUI，Language: Swift
4. 勾选 SwiftData（Use SwiftData 勾上）
5. 选好存放目录（~/Projects/ONTHERACK）
6. 创建后把 `ONTHERACK/` 目录下的 .swift 文件全部拖进 Xcode 项目
7. 删掉 Xcode 自动生成的 ContentView.swift（用我的替换）
8. 打开 ONTHERACKApp.swift，确认它是 @main 入口

## 项目结构

```
ONTHERACK/
├── Package.swift              # Swift Package 定义（Xcode 16+ 可用）
├── PRD.md                     # 产品需求文档
├── ONTHERACK/
│   ├── ONTHERACKApp.swift     # App 入口 + SwiftData 初始化
│   ├── ContentView.swift      # 主 TabView + 颜色定义
│   ├── Info.plist             # App 配置
│   ├── Models/
│   │   └── Workout.swift      # 所有数据模型
│   ├── Views/
│   │   ├── HomeView.swift     # 首页 + 训练类型选择
│   │   ├── WorkoutView.swift  # 训练中界面
│   │   ├── HistoryView.swift  # 历史 + 图表
│   │   └── SettingsView.swift # 设置 + 体重追踪
│   ├── ViewModels/
│   │   └── WorkoutViewModel.swift
│   ├── Services/
│   │   ├── WorkoutService.swift
│   │   └── ProgressionService.swift
│   ├── Components/
│   │   ├── RestTimerView.swift
│   │   ├── PlateCalculatorView.swift
│   │   └── WarmupCalculatorView.swift
│   └── Resources/
│       └── Assets.xcassets/
│           ├── Contents.json
│           ├── AccentColor.colorset/
│           └── AppIcon.appiconset/
└── README.md
```

## 功能清单

- [x] 5x5 训练模板（Workout A / B 自动切换）
- [x] 健身五大动作：深蹲、卧推、划船、推举、硬拉
- [x] 组次记录 + 失败组标记
- [x] 渐进超负荷（自动加重量）
- [x] Deload 判断（连续 3 次失败自动建议）
- [x] 历史图表（Swift Charts 重量曲线）
- [x] 组间休息计时器
- [x] 杠铃片计算器
- [x] 热身组计算器
- [x] 体重追踪
- [x] 深色模式（默认）
- [x] 单手操作优化

## 技术栈

- **语言**: Swift 6
- **UI**: SwiftUI
- **数据**: SwiftData（本地存储，不上云）
- **图表**: Swift Charts
- **最低版本**: iOS 18
