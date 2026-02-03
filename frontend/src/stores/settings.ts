import { defineStore } from 'pinia'

export interface SettingsState {
  theme: 'light' | 'dark'
  wallpaper: string
  fontSize: 'small' | 'normal' | 'large'
  sendKey: 'enter' | 'ctrl_enter'
}

export const useSettingsStore = defineStore('settings', {
  state: (): SettingsState => ({
    theme: (localStorage.getItem('settings_theme') as 'light' | 'dark') || 'light',
    wallpaper: localStorage.getItem('settings_wallpaper') || '',
    fontSize: (localStorage.getItem('settings_fontSize') as 'small' | 'normal' | 'large') || 'normal',
    sendKey: (localStorage.getItem('settings_sendKey') as 'enter' | 'ctrl_enter') || 'enter',
  }),
  actions: {
    setTheme(theme: 'light' | 'dark') {
      console.log('[SettingsStore] Setting theme to:', theme)
      this.theme = theme
      localStorage.setItem('settings_theme', theme)
      // Toggle tailwind dark mode class
      const html = document.documentElement
      if (theme === 'dark') {
        html.classList.add('dark')
        console.log('[SettingsStore] Added dark class to html. Classes:', html.className)
      } else {
        html.classList.remove('dark')
        console.log('[SettingsStore] Removed dark class from html. Classes:', html.className)
      }
    },
    setWallpaper(wallpaper: string) {
      this.wallpaper = wallpaper
      localStorage.setItem('settings_wallpaper', wallpaper)
    },
    setFontSize(size: 'small' | 'normal' | 'large') {
      this.fontSize = size
      localStorage.setItem('settings_fontSize', size)
    },
    setSendKey(key: 'enter' | 'ctrl_enter') {
      this.sendKey = key
      localStorage.setItem('settings_sendKey', key)
    },
    clearCache() {
      // Clear all settings except theme maybe? Or just chat related stuff? 
      // For now, let's just clear wallpaper
      this.wallpaper = ''
      localStorage.removeItem('settings_wallpaper')
    }
  }
})
