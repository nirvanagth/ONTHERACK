# ONTHERACK — 5x5 健身记录 App

## 概述

ONTHERACK 是一个原生 iOS 健身记录 App，专为 StrongLifts 5x5 训练计划设计。帮助用户记录每一次训练，追踪渐进超负荷，直观看到力量增长曲线。

技术栈：Swift + SwiftUI + SwiftData（本地存储，无需联网）

---

## 核心功能

### 1. 5x5 训练计划模板

预设五大动作，按训练日 A/B 交替：

**Workout A**
- 杠铃深蹲 (Barbell Squat) — 5组 x 5次
- 杠铃卧推 (Barbell Bench Press) — 5组 x 5次
- 杠铃划船 (Barbell Row) — 5组 x 5次

**Workout B**
- 杠铃深蹲 (Barbell Squat) — 5组 x 5次
- 站姿推举 (Overhead Press) — 5组 x 5次
- 硬拉 (Deadlift) — 1组 x 5次（硬拉只做1组，这是5x5的规则）
- 引体向上 / 辅助动作（可选附加）

允许用户：
- 修改动作名称
- 添加自定义动作
- 调整组数/次数
- 切换 A/B 日

### 2. 训练记录

每次训练页面：
- 当前训练日期
- 按顺序显示动作列表
- 每个动作显示：动作名、当前重量、组数x次数
- 一组完成后打勾，自动进入组间休息计时
- 记录失败组（完成次数少于目标）
- 支持中途暂停/继续

### 3. 渐进超负荷

- 每次成功完成 5x5 后，自动建议增加重量
  - 深蹲/硬拉：+5 lbs (2.5 kg)
  - 卧推/推举/划船：+5 lbs (2.5 kg)
- 可手动调整加重量
- 记录当前所有动作的工作重量

### 4. Deload 判断

- 连续 3 次训练同一重量失败（某一组没做满5次）→ 自动建议 deload
- Deload：重量减少 10-20%，然后重新开始递增
- 记录 deload 历史

### 5. 历史与图表

- 按日期查看训练历史
- 每个动作的**重量-时间曲线图**
- 1RM 估算（基于 Epley 公式：1RM = w × (1 + r/30)）
- 周/月训练频率统计

### 6. 辅助功能

- **热身组计算器**：输入工作重量，自动推荐热身组
  - 空杠 x 10
  - 50% x 5
  - 70% x 3
  - 工作重量 x 1
- **杠铃片计算器**：输入重量，告诉用户左右各上多少片（标准 45lbs 杠铃）
- **组间休息计时器**：可配置（默认 90s 非硬拉，180s 硬拉）
- **上次训练摘要**：打开 App 首页就看到上次的训练概要
- **体重追踪**：可选记录，图表显示

---

## 数据模型

```
Workout
  - id: UUID
  - date: Date
  - type: WorkoutType (A / B)
  - duration: TimeInterval (可选)
  - exercises: [ExerciseRecord]
  - notes: String

ExerciseRecord
  - id: UUID
  - exerciseName: String
  - isPrimary: Bool (五大动作 vs 辅助动作)
  - sets: [SetRecord]
  - warmupSets: [SetRecord] (可选)

SetRecord
  - id: UUID
  - weight: Double (lbs)
  - reps: Int
  - completedReps: Int (失败时记录实际完成数)
  - isCompleted: Bool

Progression
  - exerciseName: String
  - currentWeight: Double
  - lastUpdated: Date
  - deloadCount: Int
```

---

## 设计原则

- **单手操作**：训练时大概率一只手握杠铃杆，所有操作拇指可及
- **打开即用**：首页显示"上次训练"和"开始今日训练"
- **极简输入**：点击即完成一组，不需要跳转/滑菜单
- 深色模式优先（健身房灯光暗），支持浅色
- 所有数据存本地（SwiftData / CoreData），不上云

---

## UI 结构

```
Tab 1: HOME
  - 上次训练摘要卡片
  - "开始今日训练"大按钮
  - 本周训练进度

Tab 2: WORKOUT
  - 当前训练实时界面
  - 动作列表 -> 点击动作展开组详情
  - 组间计时器浮窗
  - 完成按钮

Tab 3: HISTORY
  - 按月份/周分组的历史列表
  - 点击查看单次训练详情
  - 每个动作的进度图表（用 Swift Charts）

Tab 4: SETTINGS
  - 修改各动作当前重量
  - 设置 deload 阈值
  - 设置休息时间
  - 体重追踪
  - 单位切换 (lbs/kg)
  - 数据导出
```

---

## 第一阶段 MVP（先不做）

- ❌ iCloud 同步
- ❌ Apple Watch
- ❌ 数据导出
- ❌ 通知/提醒
- ❌ 社交功能 / 分享

---

## 配色

- 主色：深灰/黑 + 橙红色 (#FF4500) 作为强调色
- 背景：暗色 (#1C1C1E)
- 卡片：稍亮 (#2C2C2E)
- 字色：白色主字，灰色副字
- 完成状态的勾：绿色

---

## 项目结构建议

```
ONTHERACK/
├── ONTHERACK.xcodeproj
├── ONTHERACK/
│   ├── ONTHERACKApp.swift
│   ├── Models/
│   │   ├── Workout.swift
│   │   ├── Exercise.swift
│   │   └── Set.swift
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── WorkoutView.swift
│   │   ├── HistoryView.swift
│   │   └── SettingsView.swift
│   ├── ViewModels/
│   │   └── WorkoutViewModel.swift
│   ├── Services/
│   │   ├── WorkoutService.swift
│   │   └── ProgressionService.swift
│   ├── Components/
│   │   ├── ExerciseRow.swift
│   │   ├── SetRow.swift
│   │   ├── RestTimer.swift
│   │   ├── PlateCalculator.swift
│   │   └── ProgressChart.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Preview Content/
└── PRD.md
```
