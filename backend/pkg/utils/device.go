package utils

import (
	"github.com/mssola/useragent"
)

// ParseDevice 从 User-Agent 字符串解析设备名称
// 返回如 "iPhone" / "Android" / "Chrome 120 on macOS" 等
func ParseDevice(uaString string) string {
	ua := useragent.New(uaString)

	// 优先判断移动设备
	if ua.Mobile() {
		platform := ua.Platform()
		if platform != "" {
			return platform // e.g., "iPhone", "Android"
		}
		return "Mobile Device"
	}

	// 桌面设备：浏览器 + 操作系统
	browser, version := ua.Browser()
	os := ua.OS()

	if browser != "" && os != "" {
		// 简化版本号，只取主版本
		if len(version) > 3 {
			version = version[:3]
		}
		return browser + " on " + os
	}

	if os != "" {
		return os
	}

	return "Unknown Device"
}
