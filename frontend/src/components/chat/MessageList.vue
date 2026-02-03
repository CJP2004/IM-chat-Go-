<template>
  <div class="flex-1 overflow-y-auto p-4 bg-transparent" ref="container">
    <div v-if="messages.length === 0" class="h-full flex flex-col items-center justify-center text-gray-400 dark:text-gray-500">
        <ChatBubbleOvalLeftEllipsisIcon class="w-16 h-16 mb-4 opacity-50" />
        <p>No messages yet. Start a conversation!</p>
    </div>
    
    <MessageBubble 
        v-for="(msg, index) in groupedMessages" 
        :key="index"
        :msg="msg"
        :isSelf="msg.senderId === currentUserId"
        :avatar="msg.senderId === currentUserId ? currentUserAvatar : receiverAvatar"
        :username="msg.senderId === currentUserId ? 'You' : (receiverName || 'User')"
        :showStatus="msg.showStatus"
        :isFirstInGroup="msg.isFirstInGroup"
        :isLastInGroup="msg.isLastInGroup"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
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

const groupedMessages = computed(() => {
    return props.messages.map((msg, index) => {
        const prevMsg = props.messages[index - 1]
        const nextMsg = props.messages[index + 1]

        const isFirstInGroup = !prevMsg || prevMsg.senderId !== msg.senderId
        const isLastInGroup = !nextMsg || nextMsg.senderId !== msg.senderId
        
        // Calculate status visibility (only for last self message)
        // Find the absolute last index of self message
        let isLastSelfMessage = false
        if (msg.senderId === props.currentUserId) {
             // Check if this is truly the last self message in the entire list
             // optimization: could be pre-calculated, but map is fine for chat length
             let isLast = true
             for (let i = index + 1; i < props.messages.length; i++) {
                 if (props.messages[i].senderId === props.currentUserId) {
                     isLast = false
                     break
                 }
             }
             isLastSelfMessage = isLast
        }

        return {
            ...msg,
            isFirstInGroup,
            isLastInGroup,
            showStatus: isLastSelfMessage
        }
    })
})



watch(() => props.messages.length, scrollToBottom)
</script>
