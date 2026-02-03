<template>
  <div class="flex-1 flex flex-col h-full bg-white dark:bg-gray-900 transition-colors duration-200">
    <template v-if="chatStore.activeReceiverId">
       <ChatHeader 
            :title="currentContact?.username || 'Chat'" 
            :avatar="currentContact?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${currentContact?.username}`"
            :tagline="currentContact?.tagline"
       />
       
       <div class="flex-1 flex flex-col min-h-0 relative" :style="wallpaperStyle">
         <MessageList 
            :messages="filteredMessages"
            :currentUserId="userStore.user?.id || 0"
            :currentUserAvatar="userStore.user?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${userStore.user?.username}`"
            :receiverAvatar="currentContact?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${currentContact?.username}`"
            :currentUserName="userStore.user?.username || 'You'"
            :receiverName="currentContact?.username || 'User'"
         />
       </div>
       
       <ChatInput @send="handleSend" @upload="handleUpload" />
    </template>
    
    <div v-else class="flex-1 flex flex-col items-center justify-center text-gray-400 dark:text-gray-500 bg-gray-50/30 dark:bg-gray-900/50">
        <div class="w-24 h-24 bg-amber-100/50 dark:bg-gray-800 rounded-full flex items-center justify-center mb-6">
            <ChatBubbleLeftRightIcon class="w-12 h-12 text-amber-400 dark:text-amber-500" />
        </div>
        <h3 class="text-xl font-semibold text-gray-700 dark:text-gray-200 mb-2">Welcome to IM Chat</h3>
        <p class="max-w-xs text-center text-sm">Select a contact from the sidebar to start messaging.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useUserStore } from '../../stores/user'
import { useChatStore } from '../../stores/chat'
import ChatHeader from './ChatHeader.vue'
import MessageList from './MessageList.vue'
import ChatInput from './ChatInput.vue'
import { ChatBubbleLeftRightIcon } from '@heroicons/vue/24/outline'

import { useSettingsStore } from '../../stores/settings'

const userStore = useUserStore()
const chatStore = useChatStore()
const settingsStore = useSettingsStore()

const wallpaperStyle = computed(() => {
    if (!settingsStore.wallpaper) return {}
    return {
        backgroundColor: settingsStore.wallpaper
    }
})

const currentContact = computed(() => {
    return chatStore.users.find(u => u.id === chatStore.activeReceiverId)
})

const filteredMessages = computed(() => {
    return chatStore.messages.filter(msg => {
         return (msg.senderId === chatStore.activeReceiverId && msg.receiverId === userStore.user?.id) || 
                (msg.senderId === userStore.user?.id && msg.receiverId === chatStore.activeReceiverId)
    })
})

import { watch } from 'vue'

// 监听消息变化，自动发送已读回执
watch(() => chatStore.messages.length, () => {
    if (chatStore.activeReceiverId) {
        chatStore.sendReadAck()
    }
})

// 监听当前聊天对象变化
watch(() => chatStore.activeReceiverId, (newId) => {
    if (newId) {
        chatStore.sendReadAck()
    }
})

const handleSend = (text: string) => {
    chatStore.sendMessage(text)
}

const handleUpload = async (file: File) => {
    try {
        const url = await chatStore.uploadImage(file)
        chatStore.sendMessage('[Image]', 'image', url)
    } catch (e) {
        console.error(e)
        alert('Failed to upload image')
    }
}
</script>
