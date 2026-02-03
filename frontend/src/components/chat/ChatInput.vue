<template>
  <div class="p-6 bg-transparent">
    <div class="flex items-center space-x-2 bg-white dark:bg-gray-800 rounded-3xl p-2 px-4 shadow-lg shadow-gray-200/50 dark:shadow-black/20 border border-gray-100 dark:border-gray-700 transition-colors duration-200">
        
        <!-- Microphone (Placeholder) -->
        <button class="text-gray-400 dark:text-gray-500 hover:text-amber-500 transition p-2">
            <MicrophoneIcon class="w-6 h-6" />
        </button>

        <!-- Text Area -->
        <textarea 
            v-model="text"
            rows="1"
            class="flex-1 bg-transparent border-none focus:ring-0 focus:outline-none focus:border-none outline-none ring-0 text-gray-700 dark:text-gray-100 placeholder-gray-400 resize-none py-3 max-h-32"
            placeholder="Type a message..."
            @keydown.enter.prevent="send"
        ></textarea>

        <!-- Actions -->
        <div class="flex items-center space-x-1 text-gray-400 dark:text-gray-500">
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
import { ref } from 'vue'
import { PhotoIcon, PaperAirplaneIcon, MicrophoneIcon, FaceSmileIcon } from '@heroicons/vue/24/outline'

const emit = defineEmits(['send', 'upload'])
const text = ref('')

const send = () => {
    if (!text.value.trim()) return
    emit('send', text.value)
    text.value = ''
}

const handleUpload = (e: any) => {
    const file = e.target.files[0]
    if (file) emit('upload', file)
}
</script>
