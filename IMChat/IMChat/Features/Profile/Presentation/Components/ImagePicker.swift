/*
FILE-GUIDE: ImagePicker.swift
- UIKit 的 UIImagePickerController 与 SwiftUI 的桥接组件。
- 通过 Coordinator 回传用户选择结果或取消事件。
- ProfileView 用它完成相机/相册能力接入。
*/

import SwiftUI
import UIKit

/// 系统图片选择器（相机/相册）
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    /// 创建并配置系统图片选择控制器。
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    /// SwiftUI 更新 UIKit 控制器时的回调；当前组件无需动态更新。
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    /// 创建桥接代理 Coordinator，用于接收选择器回调事件。
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImagePicked: (UIImage) -> Void
        private let onCancel: () -> Void

        /// 注入“选择完成/取消”两个回调闭包。
        init(onImagePicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        /// 用户取消选择时回调给上层页面关闭弹窗。
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }

        /// 用户完成选择时优先返回裁剪图，否则返回原图；都取不到则按取消处理。
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let edited = info[.editedImage] as? UIImage {
                onImagePicked(edited)
            } else if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            } else {
                onCancel()
            }
        }
    }
}
