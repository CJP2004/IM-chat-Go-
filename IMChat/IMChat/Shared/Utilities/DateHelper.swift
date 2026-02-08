/*
FILE-GUIDE: DateHelper.swift
- 时间格式化工具：把消息时间转成列表友好文案。
- 当天显示 HH:mm，非当天显示 yyyy-MM-dd。
- 解析失败时回退原字符串，避免 UI 崩溃。
*/

import Foundation

struct DateHelper {
    /// 把后端时间字符串格式化为列表展示文案：当天显示 `HH:mm`，非当天显示 `yyyy-MM-dd`。
    static func formatMessageTime(_ timeString: String) -> String {
        // 假设输入格式为 "yyyy-MM-dd HH:mm:ss" 或 "yyyy-MM-dd HH:mm"
        // 尝试解析
        let parser = DateFormatter()
        // 尝试多种可能的格式
        let formats = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm"]
        
        var date: Date?
        
        for format in formats {
            parser.dateFormat = format
            if let d = parser.date(from: timeString) {
                date = d
                break
            }
        }
        
        // 如果解析失败，尝试作为 "Today", "Yesterday" 等自然语言处理，或者直接返回原字符串
        // 但这里我们主要处理标准时间格式
        guard let validDate = date else {
            return timeString
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(validDate) {
            // 当天 -> 显示 "HH:mm" (例如 14:30)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: validDate)
        } else {
            // 非当天 -> 显示 "yyyy-MM-dd" (例如 2026-02-04)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: validDate)
        }
    }
}
