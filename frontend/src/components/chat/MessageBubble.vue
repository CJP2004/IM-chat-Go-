<template>
  <div :class="['flex w-full relative group', isLastInGroup ? 'mb-6' : 'mb-1', isSelf ? 'justify-end' : 'justify-start']">
    
    <!-- Receiver Avatar (Left) -->
    <div v-if="!isSelf" :class="['flex-shrink-0 mr-2 flex flex-col justify-start', isFirstInGroup ? 'opacity-100' : 'invisible']">
       <img :src="avatar" class="w-8 h-8 rounded-full object-cover shadow-sm bg-gray-200" />
    </div>

    <!-- Message Content Column -->
    <div :class="['flex flex-col', isSelf ? 'items-end' : 'items-start', isFirstInGroup ? 'mt-6' : '']" style="max-width: 70%;">
       
       <!-- Bubble Container -->
       <div class="relative">
           <!-- The Bubble -->
           <div :class="[
             'px-4 py-2 shadow-sm relative leading-relaxed transition-all duration-200 break-words text-[15px]',
             textSizeClass,
             isSelf 
               ? 'bg-amber-500 text-white rounded-3xl' 
               : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-100 rounded-3xl border border-gray-100 dark:border-gray-600',
             // Corner logic: TOP corners on FIRST message
             isSelf && isFirstInGroup ? 'rounded-tr-sm' : '', // Self first: sharp top-right
             !isSelf && isFirstInGroup ? 'rounded-tl-sm' : '' // Other first: sharp top-left
           ]">
              <!-- Image Content -->
              <div v-if="msg.type === 'image'" class="-m-2">
                <img :src="msg.mediaUrl" class="rounded-xl max-w-full cursor-pointer hover:opacity-95 transition block" />
              </div>
              <!-- Text Content -->
              <div v-else class="whitespace-pre-wrap">
                {{ msg.content }}
              </div>
           </div>
       </div>

       <!-- Footer Info (Status) -->
       <div v-if="isSelf && showStatus && isLastInGroup" class="mt-1 mr-3 text-[10px] font-medium text-gray-400">
           {{ msg.isRead ? 'Read' : 'Delivered' }}
       </div>
    </div>

    <!-- Sender Avatar (Right) -->
    <div v-if="isSelf" :class="['flex-shrink-0 ml-2 flex flex-col justify-start', isFirstInGroup ? 'opacity-100' : 'invisible']">
       <img :src="avatar" class="w-8 h-8 rounded-full object-cover shadow-sm bg-gray-200" />
    </div>
    
  </div>
</template>


<script setup lang="ts">
import { computed } from 'vue'
import { useSettingsStore } from '../../stores/settings'

const props = defineProps<{
    msg: any
    isSelf: boolean
    avatar: string
    username?: string
    showStatus?: boolean
    isFirstInGroup?: boolean // New computed prop
    isLastInGroup?: boolean // New computed prop
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
