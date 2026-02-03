<template>
  <div :class="['flex mb-6 w-full', isSelf ? 'justify-end' : 'justify-start']">
    
    <!-- Receiver Avatar (Left) -->
    <div v-if="!isSelf" class="flex-shrink-0 mr-4">
       <img :src="avatar" class="w-10 h-10 rounded-full object-cover shadow-sm bg-gray-200" />
    </div>

    <div :class="['flex flex-col', isSelf ? 'items-end' : 'items-start']" style="max-w: 65%;">
       
       <!-- Header Info -->
       <div class="flex items-center mb-1 text-xs">
          <template v-if="!isSelf">
             <span class="font-bold text-gray-800 dark:text-gray-200 mr-2 text-sm">{{ username }}</span>
             <span class="text-gray-400 dark:text-gray-400">{{ formatTime(msg.CreatedAt || msg.created_at) }}</span>
          </template>
          <template v-else>
             <span class="text-gray-400 dark:text-gray-400 mr-2">{{ formatTime(msg.CreatedAt || msg.created_at) }}</span>
             <span class="font-bold text-gray-800 dark:text-gray-200 mr-2 text-sm">You</span>
          </template>
       </div>

       <!-- Bubble -->
       <div :class="[
         'p-4 shadow-sm rounded-2xl relative leading-relaxed transition-all duration-200',
         textSizeClass,
         isSelf 
           ? 'bg-amber-600 text-white rounded-tr-none' 
           : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-100 rounded-tl-none border border-gray-100 dark:border-gray-600'
       ]">
          <!-- Image Content -->
          <div v-if="msg.type === 'image'" class="-m-2">
            <img :src="msg.mediaUrl" class="rounded-xl max-w-full cursor-pointer hover:opacity-95 transition block" />
          </div>
          <!-- Text Content -->
          <div v-else>
            {{ msg.content }}
          </div>
       </div>

       <!-- Footer Info (Optional, like links or attachments preview) -->
    </div>

    <!-- Sender Avatar (Right) -->
    <div v-if="isSelf" class="flex-shrink-0 ml-4">
       <img :src="avatar" class="w-10 h-10 rounded-full object-cover shadow-sm bg-gray-200" />
    </div>

  </div>
</template>


<script setup lang="ts">
import { defineProps, computed } from 'vue'
import { useSettingsStore } from '../../stores/settings'
import { formatTime } from '../../utils/date'

const props = defineProps<{
    msg: any
    isSelf: boolean
    avatar: string
    username?: string // Added username prop
}>()

const settingsStore = useSettingsStore()

const textSizeClass = computed(() => {
    switch (settingsStore.fontSize) {
        case 'small': return 'text-xs'
        case 'normal': return 'text-sm'
        case 'large': return 'text-lg'
        default: return 'text-sm'
    }
})
</script>
