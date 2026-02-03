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
           <!-- Image Content (No bubble wrapper) -->
           <div v-if="msg.type === 'image'" class="overflow-hidden rounded-2xl shadow-sm">
             <img 
               :src="msg.mediaUrl" 
               class="max-w-full cursor-zoom-in hover:opacity-90 transition block" 
               style="max-width: 300px;" 
               @click="openLightbox"
             />
           </div>
           
           <!-- The Bubble (Text only) -->
           <div v-else :class="[
             'px-4 py-2 shadow-sm relative leading-relaxed transition-all duration-200 break-words text-[15px]',
             textSizeClass,
             isSelf 
               ? 'bg-amber-500 text-white rounded-3xl' 
               : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-100 rounded-3xl border border-gray-100 dark:border-gray-600',
             // Corner logic: TOP corners on FIRST message
             isSelf && isFirstInGroup ? 'rounded-tr-sm' : '', // Self first: sharp top-right
             !isSelf && isFirstInGroup ? 'rounded-tl-sm' : '' // Other first: sharp top-left
           ]">
              <!-- Text Content -->
              <div class="whitespace-pre-wrap">
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

    <!-- Image Lightbox Modal -->
    <Teleport to="body">
      <div 
        v-if="showLightbox" 
        class="fixed inset-0 z-[9999] bg-black/90 flex items-center justify-center cursor-zoom-out"
        @click="closeLightbox"
      >
        <img 
          :src="msg.mediaUrl" 
          class="max-w-[90vw] max-h-[90vh] object-contain rounded-lg shadow-2xl"
          @click.stop
        />
        <!-- Close Button -->
        <button 
          @click="closeLightbox"
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
import { computed, ref } from 'vue'
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
const showLightbox = ref(false)

const textSizeClass = computed(() => {
    switch (settingsStore.fontSize) {
        case 'small': return 'text-xs'
        case 'normal': return 'text-sm'
        case 'large': return 'text-lg'
        default: return 'text-sm'
    }
})

const openLightbox = () => {
    showLightbox.value = true
    // 禁止背景滚动
    document.body.style.overflow = 'hidden'
}

const closeLightbox = () => {
    showLightbox.value = false
    document.body.style.overflow = ''
}
</script>

