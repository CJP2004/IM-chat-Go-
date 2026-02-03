<template>
  <div class="flex-1 overflow-y-auto p-4 bg-transparent" ref="container">
    <div v-if="messages.length === 0" class="h-full flex flex-col items-center justify-center text-gray-400 dark:text-gray-500">
        <ChatBubbleOvalLeftEllipsisIcon class="w-16 h-16 mb-4 opacity-50" />
        <p>No messages yet. Start a conversation!</p>
    </div>
    
    <!-- Render grouped messages -->
    <template v-for="(item, index) in displayItems" :key="index">
      <!-- Image Stack (multiple consecutive images) -->
      <div 
        v-if="item.type === 'imageStack'" 
        :class="['flex w-full mb-6', item.isSelf ? 'justify-end' : 'justify-start']"
      >
        <!-- Receiver Avatar (Left) -->
        <div v-if="!item.isSelf" class="flex-shrink-0 mr-2">
          <img :src="receiverAvatar" class="w-8 h-8 rounded-full object-cover shadow-sm bg-gray-200" />
        </div>
        
        <div class="flex flex-col" :class="[item.isSelf ? 'items-end' : 'items-start']">
          <ImageStack 
            :cardsData="item.images"
            :cardDimensions="{ width: 180, height: 180 }"
            :randomRotation="true"
            :sendToBackOnClick="true"
            @cardClick="handleStackCardClick"
          />
        </div>
        
        <!-- Sender Avatar (Right) -->
        <div v-if="item.isSelf" class="flex-shrink-0 ml-2">
          <img :src="currentUserAvatar" class="w-8 h-8 rounded-full object-cover shadow-sm bg-gray-200" />
        </div>
      </div>
      
      <!-- Single Message -->
      <MessageBubble 
        v-else
        :msg="item.msg"
        :isSelf="item.msg.senderId === currentUserId"
        :avatar="item.msg.senderId === currentUserId ? currentUserAvatar : receiverAvatar"
        :username="item.msg.senderId === currentUserId ? 'You' : (receiverName || 'User')"
        :showStatus="item.msg.showStatus"
        :isFirstInGroup="item.msg.isFirstInGroup"
        :isLastInGroup="item.msg.isLastInGroup"
      />
    </template>
    
    <!-- Lightbox for Stack Image -->
    <Teleport to="body">
      <div 
        v-if="stackLightbox.show" 
        class="fixed inset-0 z-[9999] bg-black/90 flex items-center justify-center cursor-zoom-out"
        @click="closeStackLightbox"
      >
        <img 
          :src="stackLightbox.url" 
          class="max-w-[90vw] max-h-[90vh] object-contain rounded-lg shadow-2xl"
          @click.stop
        />
        <button 
          @click="closeStackLightbox"
          class="absolute top-4 right-4 text-white/80 hover:text-white transition p-2"
        >
          <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
import { ChatBubbleOvalLeftEllipsisIcon } from '@heroicons/vue/24/outline'
import MessageBubble from './MessageBubble.vue'
import ImageStack from './ImageStack.vue'

const props = defineProps<{
    messages: any[]
    currentUserId: number
    currentUserAvatar: string
    receiverAvatar: string
    currentUserName: string
    receiverName: string
}>()

const container = ref<HTMLElement | null>(null)
const stackLightbox = ref({ show: false, url: '' })

const scrollToBottom = async () => {
    await nextTick()
    if (container.value) {
        container.value.scrollTop = container.value.scrollHeight
    }
}

// 处理堆叠图片点击
const handleStackCardClick = (card: { id: number; img: string }) => {
    stackLightbox.value = { show: true, url: card.img }
    document.body.style.overflow = 'hidden'
}

const closeStackLightbox = () => {
    stackLightbox.value.show = false
    document.body.style.overflow = ''
}

// 将连续的图片消息分组
const displayItems = computed(() => {
    const items: any[] = []
    let i = 0
    
    while (i < props.messages.length) {
        const msg = props.messages[i]
        
        // 检查是否是图片消息
        if (msg.type === 'image') {
            // 收集同一发送者的连续图片消息
            const images: { id: number; img: string }[] = []
            const senderId = msg.senderId
            let j = i
            
            while (j < props.messages.length && 
                   props.messages[j].type === 'image' && 
                   props.messages[j].senderId === senderId) {
                images.push({ id: j, img: props.messages[j].mediaUrl })
                j++
            }
            
            // 如果有多张图片，用 ImageStack 显示
            if (images.length > 1) {
                items.push({
                    type: 'imageStack',
                    isSelf: senderId === props.currentUserId,
                    images: images
                })
                i = j // 跳过所有已处理的图片
            } else {
                // 单张图片，正常显示
                items.push({
                    type: 'single',
                    msg: addGroupInfo(msg, i)
                })
                i++
            }
        } else {
            // 非图片消息，正常显示
            items.push({
                type: 'single',
                msg: addGroupInfo(msg, i)
            })
            i++
        }
    }
    
    return items
})

// 添加分组信息
function addGroupInfo(msg: any, index: number) {
    const prevMsg = props.messages[index - 1]
    const nextMsg = props.messages[index + 1]

    const isFirstInGroup = !prevMsg || prevMsg.senderId !== msg.senderId
    const isLastInGroup = !nextMsg || nextMsg.senderId !== msg.senderId
    
    // Calculate status visibility (only for last self message)
    let isLastSelfMessage = false
    if (msg.senderId === props.currentUserId) {
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
}

watch(() => props.messages.length, scrollToBottom)
</script>

