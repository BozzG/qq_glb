//
//  QianqianWidget.swift
//  QianqianWidget
//
//  芊芊成长手账 · 桌面小组件（P1-7，只读「今日日程概览」）。
//  数据来源：主 App 通过 home_widget 写入 App Group 共享的 UserDefaults。
//  契约（须与 lib/services/widget_service.dart 保持一致）：
//    App Group : group.com.qianqian.qianqianGrowthLogbook
//    today_schedules : JSON 数组，元素 { title, time(HH:mm), icon(emoji), color(ARGB int), checked }
//    today_date      : 日期文案，如「6月23日 周一」
//    today_count     : 今日日程总数
//

import WidgetKit
import SwiftUI

// MARK: - 数据模型（与 Flutter 写入的 JSON 字段对齐）

struct ScheduleItem: Codable, Hashable {
    let title: String
    let time: String
    let icon: String
    let color: Int
    let checked: Bool
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let dateLabel: String
    let count: Int
    let items: [ScheduleItem]
}

// MARK: - App Group 读取

enum WidgetStore {
    static let appGroupId = "group.com.qianqian.qianqianGrowthLogbook"
    static let payloadKey = "today_schedules"
    static let dateKey = "today_date"
    static let countKey = "today_count"

    static func load() -> TodayEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let dateLabel = defaults?.string(forKey: dateKey) ?? defaultDateLabel()
        let count = defaults?.integer(forKey: countKey) ?? 0
        var items: [ScheduleItem] = []
        if let raw = defaults?.string(forKey: payloadKey),
           let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ScheduleItem].self, from: data) {
            items = decoded
        }
        return TodayEntry(date: Date(), dateLabel: dateLabel, count: count, items: items)
    }

    static func defaultDateLabel() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEE"
        return f.string(from: Date())
    }
}

// MARK: - 颜色工具 & 配色（呼应 App 玫瑰粉 / Wine Rose 体系）

extension Color {
    init(argb: Int) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a == 0 ? 1 : a)
    }
}

enum Palette {
    static let accent = Color(argb: 0xFFC9526E)
    static let bg = Color(argb: 0xFFFBF8F7)
    static let ink = Color(argb: 0xFF2B1E22)
    static let inkSoft = Color(argb: 0xFF7A6268)
    static let hair = Color(argb: 0xFFEDE6E7)
}

// MARK: - TimelineProvider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(
            date: Date(),
            dateLabel: WidgetStore.defaultDateLabel(),
            count: 2,
            items: [
                ScheduleItem(title: "钢琴课", time: "09:00", icon: "🎹", color: 0xFFC9526E, checked: true),
                ScheduleItem(title: "户外活动", time: "16:30", icon: "🌳", color: 0xFF7BA05B, checked: false),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(WidgetStore.load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = WidgetStore.load()
        // 跨过次日 0 点后让系统刷新一次，保证「今日」随自然日滚动。
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Views

struct QianqianWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TodayEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
        default:
            wideBody
        }
    }

    private var header: some View {
        HStack {
            Text(entry.dateLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Palette.ink)
            Spacer()
            Text("\(entry.count) 项")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Palette.accent)
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Rectangle().fill(Palette.hair).frame(height: 1)
            if entry.items.isEmpty {
                Spacer()
                Text("今天没有安排\n好好休息～")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.inkSoft)
                Spacer()
            } else {
                ForEach(entry.items.prefix(3), id: \.self) { item in
                    compactRow(item)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var wideBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Rectangle().fill(Palette.hair).frame(height: 1)
            if entry.items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("今天没有安排，好好休息～")
                        .font(.system(size: 14))
                        .foregroundColor(Palette.inkSoft)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.items.prefix(family == .systemLarge ? 8 : 3), id: \.self) { item in
                    row(item)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func row(_ item: ScheduleItem) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(argb: item.color))
                .frame(width: 4, height: 28)
            Text(item.icon).font(.system(size: 16))
            Text(item.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Palette.ink)
                .strikethrough(item.checked, color: Palette.inkSoft)
                .lineLimit(1)
            Spacer()
            if item.checked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.accent)
            } else {
                Text(item.time)
                    .font(.system(size: 12))
                    .foregroundColor(Palette.inkSoft)
            }
        }
    }

    private func compactRow(_ item: ScheduleItem) -> some View {
        HStack(spacing: 6) {
            Circle().fill(Color(argb: item.color)).frame(width: 6, height: 6)
            Text(item.title)
                .font(.system(size: 12))
                .foregroundColor(Palette.ink)
                .strikethrough(item.checked, color: Palette.inkSoft)
                .lineLimit(1)
            Spacer()
            if item.checked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Palette.accent)
            } else {
                Text(item.time)
                    .font(.system(size: 10))
                    .foregroundColor(Palette.inkSoft)
            }
        }
    }
}

// MARK: - Widget

struct QianqianWidget: Widget {
    let kind: String = "QianqianWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                QianqianWidgetEntryView(entry: entry)
                    .padding(14)
                    .containerBackground(Palette.bg, for: .widget)
            } else {
                QianqianWidgetEntryView(entry: entry)
                    .padding(14)
                    .background(Palette.bg)
            }
        }
        .configurationDisplayName("芊芊今日")
        .description("查看今天的日程安排与打卡情况。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    QianqianWidget()
} timeline: {
    TodayEntry(date: .now, dateLabel: "6月23日 周二", count: 2, items: [
        ScheduleItem(title: "钢琴课", time: "09:00", icon: "🎹", color: 0xFFC9526E, checked: true),
        ScheduleItem(title: "户外活动", time: "16:30", icon: "🌳", color: 0xFF7BA05B, checked: false),
    ])
}
