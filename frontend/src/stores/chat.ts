import { defineStore } from 'pinia'
import axios from 'axios'
import { useUserStore } from './user'

interface Message {
  content: string
  senderId?: number
  receiverId?: number
  type?: string
  mediaUrl?: string
  CreatedAt?: string
  isRead?: boolean
}

interface User {
  id: number
  username: string
  avatar: string
  tagline?: string
  lastMessage?: string
  lastMessageTime?: string
}

export const useChatStore = defineStore('chat', {
  state: () => ({
    messages: [] as Message[],
    users: [] as User[], // List of other users
    activeReceiverId: 0 as number,
    socket: null as WebSocket | null,
    isConnected: false,
  }),
  actions: {
    async fetchUsers() {
      const userStore = useUserStore()
      if (!userStore.user) return

      try {
        const res = await axios.get('http://localhost:2222/api/users', {
            params: { userId: userStore.user.id }
        })
        this.users = res.data.data
      } catch (e) {
        console.error("Failed to fetch users", e)
      }
    },
    setActiveReceiver(id: number) {
      this.activeReceiverId = id
      this.fetchHistory()
    },
    async fetchHistory() {
      const userStore = useUserStore()
      if (!userStore.user || !this.activeReceiverId) return

      try {
        const res = await axios.get('http://localhost:2222/api/messages', {
            params: {
                senderId: userStore.user.id,
                receiverId: this.activeReceiverId
            }
        })
        // 过滤掉当前内存中已经可能存在的重复消息（可选，这里简单全量替换或追加）
        // 简单处理：每次切换联系人，清空消息并加载历史，加上实时接收的
        this.messages = res.data.map((m: any) => ({
            content: m.Content,
            senderId: m.SenderID,
            receiverId: m.ReceiverID,
            type: m.Type,
            mediaUrl: m.MediaURL,
            CreatedAt: m.CreatedAt,
            isRead: m.IsRead
        }))
      } catch (e) {
          console.error("Failed to fetch history", e)
      }
    },
    async uploadImage(file: File) {
        const formData = new FormData()
        formData.append('file', file)
        const res = await axios.post('http://localhost:2222/api/upload', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        })
        return res.data.url
    },
    connect() {
      if (this.socket) return

      const userStore = useUserStore()
      if (!userStore.user) return 

      // Attach userId param so backend knows who we are
      this.socket = new WebSocket(`ws://localhost:2222/ws?userId=${userStore.user.id}`)

      this.socket.onopen = () => {
        this.isConnected = true
        console.log('WS Connected')
      }

      this.socket.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data)
          const userStore = useUserStore()

          // 处理已读回执
          if (data.type === 'read_ack') {
              // 如果收到的回执来自当前聊天对象，说明他读了我的消息
              if (data.senderId === this.activeReceiverId) {
                  this.messages.forEach(m => {
                      if (m.senderId === userStore.user?.id) {
                          m.isRead = true
                      }
                  })
              }
              return
          }

          // 如果接收到的消息是发给当前聊天对象的，或者是当前聊天对象发来的
          if ((data.senderId === this.activeReceiverId && data.receiverId === userStore.user?.id) ||
              (data.senderId === userStore.user?.id && data.receiverId === this.activeReceiverId)) {
               this.messages.push(data)
          }
        } catch {
          console.error("Received non-JSON message")
        }
      }

      this.socket.onclose = () => {
        this.isConnected = false
        this.socket = null
        console.log('WS Disconnected')
      }
    },
    sendMessage(content: string, type: string = 'text', mediaUrl: string = '') {
      if (this.socket && this.isConnected) {
        const userStore = useUserStore()
        const msg = {
          content,
          senderId: userStore.user?.id || 0,
          receiverId: this.activeReceiverId,
          type,
          mediaUrl,
          CreatedAt: new Date().toISOString(),
          isRead: false
        }
        this.socket.send(JSON.stringify(msg))
        
        // Optimistically append message to local view
        this.messages.push(msg)
      }
    },
    // 发送已读回执
    sendReadAck() {
        if (this.socket && this.isConnected && this.activeReceiverId) {
            const userStore = useUserStore()
            const msg = {
                senderId: userStore.user?.id || 0,
                receiverId: this.activeReceiverId,
                type: 'read_ack',
                content: 'read'
            }
            this.socket.send(JSON.stringify(msg))
        }
    },
    disconnect() {
        if (this.socket) {
            this.socket.close()
            this.socket = null
        }
    }
  }
})
