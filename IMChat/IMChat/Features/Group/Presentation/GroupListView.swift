/*
FILE-GUIDE: GroupListView.swift
- 群组模块占位页。
- 当前仅提供基础布局，后续可扩展为群列表、群详情、群消息入口。
*/

import SwiftUI

/// 群组列表页 (占位符)
struct GroupListView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Group List")
                .foregroundColor(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black) // 纯黑背景
    }
}
