<template>
  <div class="flex-1 overflow-y-auto p-4 bg-transparent" ref="container">
    <div v-if="messages.length === 0" class="h-full flex flex-col items-center justify-center text-gray-400 dark:text-gray-500">
        <ChatBubbleOvalLeftEllipsisIcon class="w-16 h-16 mb-4 opacity-50" />
        <p>No messages yet. Start a conversation!</p>
    </div>
    
    <MessageBubble 
        v-for="(msg, index) in messages" 
        :key="index"
        :msg="msg"
        :isSelf="msg.senderId === currentUserId"
        :avatar="msg.senderId === currentUserId ? currentUserAvatar : receiverAvatar"
        :username="msg.senderId === currentUserId ? 'You' : (receiverName || 'User')"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { ChatBubbleOvalLeftEllipsisIcon } from '@heroicons/vue/24/outline'
import MessageBubble from './MessageBubble.vue'

const props = defineProps<{
    messages: any[]
    currentUserId: number
    currentUserAvatar: string
    receiverAvatar: string
    currentUserName: string
    receiverName: string
}>()

const container = ref<HTMLElement | null>(null)

const scrollToBottom = async () => {
    await nextTick()
    if (container.value) {
        container.value.scrollTop = container.value.scrollHeight
    }
}

watch(() => props.messages.length, scrollToBottom)
</script>
