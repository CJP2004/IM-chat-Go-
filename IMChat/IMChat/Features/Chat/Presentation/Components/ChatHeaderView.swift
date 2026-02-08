/*
FILE-GUIDE: ChatHeaderView.swift
- 聊天页顶部组件（返回按钮、用户头像、动作按钮）。
- 设计成独立组件，便于主页面聚焦在消息和输入逻辑。
*/

import SwiftUI
import Kingfisher

/// 聊天页顶部信息栏（悬浮 + Liquid Glass）
struct ChatHeaderView: View {
    let receiver: User
    let topInset: CGFloat
    let onBack: () -> Void
    let onAction: () -> Void

    var body: some View {
        ZStack {
            HStack {
                HeaderIconButton(systemName: "chevron.left", action: onBack)
                Spacer()
                HeaderIconButton(systemName: "video.fill", action: onAction)
            }
            .padding(.horizontal, 18)
            .padding(.top, topInset + 8)

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 62, height: 62)
                        .overlay(
                            Circle()
                                .stroke(Color.theme.gold.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: Color.theme.gold.opacity(0.18), radius: 6, x: 0, y: 2)

                    KFImage(URL(string: receiver.avatar))
                        .resizable()
                        .placeholder {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        }
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                }

                HStack(spacing: 6) {
                    Text(receiver.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            .padding(.top, topInset + 10)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 顶部栏按钮
private struct HeaderIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
