<template>
  <div class="h-24 flex items-center justify-between px-8 bg-transparent z-10">
    <!-- User Info -->
    <div class="flex items-center">
      <div class="relative">
          <img :src="avatar" class="w-12 h-12 rounded-full object-cover shadow-sm bg-gray-200" />
      </div>
      <div class="ml-4">
        <h2 class="text-xl font-bold text-gray-800 dark:text-gray-100">{{ title }}</h2>
        <p class="text-amber-500 text-sm font-medium">{{ tagline || 'Mas Happy Typing...' }}</p>
      </div>
    </div>
    
    <!-- Actions -->
    <div class="flex items-center space-x-2">
        <div class="flex -space-x-2 mr-6">
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" class="w-8 h-8 rounded-full border-2 border-white dark:border-gray-800" />
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Travel" class="w-8 h-8 rounded-full border-2 border-white dark:border-gray-800" />
             <div class="w-8 h-8 rounded-full border-2 border-white dark:border-gray-800 bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-xs text-gray-500 dark:text-gray-300 font-medium">14</div>
        </div>

        <button class="text-gray-400 dark:text-gray-500 hover:text-amber-600 transition p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800">
            <VideoCameraIcon class="w-6 h-6" />
        </button>
        <button class="text-gray-400 dark:text-gray-500 hover:text-amber-600 transition p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800">
            <PhoneIcon class="w-6 h-6" />
        </button>
        <button class="text-gray-400 dark:text-gray-500 hover:text-amber-600 transition p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800">
            <EllipsisHorizontalIcon class="w-6 h-6" />
        </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { VideoCameraIcon, PhoneIcon, EllipsisHorizontalIcon } from '@heroicons/vue/24/outline'

defineProps<{
  title: string
  avatar: string
  tagline?: string
}>()
</script>
