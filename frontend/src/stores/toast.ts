import { defineStore } from 'pinia'

export interface Toast {
  id: number
  message: string
  type: 'success' | 'error' | 'info' | 'warning'
  duration?: number
}

export const useToastStore = defineStore('toast', {
  state: () => ({
    toasts: [] as Toast[],
    nextId: 1
  }),
  actions: {
    add(toast: Omit<Toast, 'id'>) {
      const id = this.nextId++
      const newToast = { ...toast, id, duration: toast.duration || 3000 }
      this.toasts.push(newToast)

      if (newToast.duration > 0) {
        setTimeout(() => {
          this.remove(id)
        }, newToast.duration)
      }
    },
    remove(id: number) {
      this.toasts = this.toasts.filter(t => t.id !== id)
    },
    success(message: string, duration = 3000) {
      this.add({ message, type: 'success', duration })
    },
    error(message: string, duration = 3000) {
      this.add({ message, type: 'error', duration })
    },
    info(message: string, duration = 3000) {
      this.add({ message, type: 'info', duration })
    },
    warning(message: string, duration = 3000) {
      this.add({ message, type: 'warning', duration })
    }
  }
})
