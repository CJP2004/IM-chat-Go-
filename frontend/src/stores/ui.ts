import { defineStore } from 'pinia'

export const useUIStore = defineStore('ui', {
  state: () => ({
    activeTab: 'chats' as 'chats' | 'contacts' | 'settings',
    sidebarOpen: true,
  }),
  actions: {
    setActiveTab(tab: 'chats' | 'contacts' | 'settings') {
      this.activeTab = tab
    },
    toggleSidebar() {
      this.sidebarOpen = !this.sidebarOpen
    }
  }
})
