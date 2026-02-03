<template>
  <div class="p-6 bg-transparent">
    <div class="flex items-end space-x-2 bg-white dark:bg-gray-800 rounded-3xl p-2 px-4 shadow-lg shadow-gray-200/50 dark:shadow-black/20 border border-gray-100 dark:border-gray-700 transition-colors duration-200">
        
        <!-- Microphone (Placeholder) -->
        <button class="text-gray-400 dark:text-gray-500 hover:text-amber-500 transition p-2 mb-1">
            <MicrophoneIcon class="w-6 h-6" />
        </button>

        <!-- Text Area (Auto-resize) -->
        <textarea 
            ref="textareaRef"
            v-model="text"
            rows="1"
            class="flex-1 bg-transparent border-none focus:ring-0 focus:outline-none focus:border-none outline-none ring-0 text-gray-700 dark:text-gray-100 placeholder-gray-400 resize-none py-3"
            :class="textareaHeight >= maxHeight ? 'overflow-y-auto' : 'overflow-hidden'"
            :style="{ height: textareaHeight + 'px', maxHeight: maxHeight + 'px' }"
            placeholder="Type a message..."
            @keydown.enter.exact.prevent="send"
            @keydown.shift.enter="newLine"
            @input="autoResize"
        ></textarea>

        <!-- Actions -->
        <div class="flex items-center space-x-1 text-gray-400 dark:text-gray-500 mb-1">
             <label class="hover:text-amber-500 transition p-2 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-full cursor-pointer">
                <input type="file" class="hidden" accept="image/*" @change="handleUpload" />
                <PhotoIcon class="w-6 h-6" />
             </label>
             <button class="hover:text-amber-500 transition p-2 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-full">
                <FaceSmileIcon class="w-6 h-6" />
             </button>
             
             <!-- Send Button -->
             <button 
                @click="send" 
                :disabled="!text.trim()"
                class="w-10 h-10 flex items-center justify-center bg-amber-500 text-white rounded-xl shadow-md shadow-amber-500/30 hover:bg-amber-600 transition disabled:opacity-50 disabled:cursor-not-allowed ml-2"
             >
                <PaperAirplaneIcon class="w-5 h-5 transform -rotate-45 ml-1 mb-0.5" />
             </button>
        </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick, onMounted } from 'vue'
import { PhotoIcon, PaperAirplaneIcon, MicrophoneIcon, FaceSmileIcon } from '@heroicons/vue/24/outline'

const emit = defineEmits(['send', 'upload'])
const text = ref('')
const textareaRef = ref<HTMLTextAreaElement | null>(null)
const textareaHeight = ref(24) // 初始高度
const minHeight = 24 // 最小高度
const maxHeight = 150 // 最大高度限制 (~6行)

// 自动调整高度
const autoResize = () => {
    if (!textareaRef.value) return
    
    // 先重置高度以获取正确的 scrollHeight
    textareaRef.value.style.height = minHeight + 'px'
    const scrollHeight = textareaRef.value.scrollHeight
    
    // 设置新高度，不超过最大值
    textareaHeight.value = Math.min(Math.max(scrollHeight, minHeight), maxHeight)
}

const send = () => {
    if (!text.value.trim()) return
    emit('send', text.value)
    text.value = ''
    // 重置高度
    nextTick(() => {
        textareaHeight.value = minHeight
    })
}

const newLine = () => {
    // Shift+Enter 允许换行，然后自动调整高度
    nextTick(autoResize)
}

const handleUpload = (e: any) => {
    const file = e.target.files[0]
    if (file) emit('upload', file)
}

onMounted(() => {
    autoResize()
})
</script>

