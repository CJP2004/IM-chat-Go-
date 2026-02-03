export const formatTime = (timeStr?: string) => {
    if (!timeStr) return ''
    const now = new Date()
    const date = new Date(timeStr)
    const diff = now.getTime() - date.getTime()
    
    // Convert to seconds
    const seconds = Math.floor(diff / 1000)

    // Within 1 hour (60 minutes)
    if (seconds < 3600) {
        const minutes = Math.floor(seconds / 60)
        return minutes <= 0 ? '刚刚' : `${minutes}分钟前`
    }
    
    // Within 24 hours
    if (seconds < 86400) {
        const hours = Math.floor(seconds / 3600)
        return `${hours}小时前`
    }
    
    // Within 3 days
    if (seconds < 259200) { // 3 * 24 * 60 * 60
        const days = Math.floor(seconds / 86400)
        return `${days}天前`
    }
    
    // Default: Date + Time (24h)
    const y = date.getFullYear()
    const m = (date.getMonth() + 1).toString().padStart(2, '0')
    const d = date.getDate().toString().padStart(2, '0')
    const h = date.getHours().toString().padStart(2, '0') // 24h
    const min = date.getMinutes().toString().padStart(2, '0')
    return `${y}-${m}-${d} ${h}:${min}`
}
