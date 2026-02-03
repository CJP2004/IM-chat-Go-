<template>
  <div class="w-80 flex flex-col bg-white dark:bg-gray-900 border-r border-gray-200 dark:border-gray-800 h-full transition-colors duration-200">
    <!-- Header -->
    <div class="p-4 flex items-center justify-between">
      <h2 class="text-xl font-bold text-gray-800 dark:text-gray-100">Messages</h2>
      <button class="p-2 rounded-lg bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-500 hover:bg-amber-100 dark:hover:bg-amber-900/30 transition">
        <PlusIcon class="w-5 h-5" />
      </button>
    </div>

    <!-- Search -->
    <div class="px-4 pb-4">
      <div class="relative">
        <MagnifyingGlassIcon class="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 dark:text-gray-500" />
        <input 
            type="text" 
            placeholder="Search conversations..." 
            class="w-full bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-200 placeholder-gray-500 dark:placeholder-gray-600 rounded-xl py-2 pl-10 pr-4 focus:outline-none focus:ring-2 focus:ring-amber-500/50 transition border-transparent border focus:bg-white dark:focus:bg-gray-800"
        />
      </div>
    </div>

    <!-- List -->
    <div class="flex-1 overflow-y-auto px-3 space-y-1 pb-4">
       <!-- Active Chat Logic: In real app, we might mix users and groups. Here we iterate chatStore.users -->
       <div 
          v-for="user in chatStore.users" 
          :key="user.id"
          @click="chatStore.setActiveReceiver(user.id)"
          :class="[
            'flex items-center p-3 rounded-xl cursor-pointer transition-all duration-200',
            chatStore.activeReceiverId === user.id 
                ? 'bg-amber-500 shadow-md shadow-amber-500/30' 
                : 'hover:bg-gray-50 dark:hover:bg-gray-800'
          ]"
       >
          <!-- Avatar -->
          <div class="relative">
            <img 
                :src="user.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${user.username}`" 
                class="w-12 h-12 rounded-full border-2 border-white"
            />
            <!-- Online status (mock) -->
            <span class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 border-2 border-white rounded-full"></span>
          </div>

          <!-- Info -->
          <div class="ml-3 flex-1 overflow-hidden">
             <div class="flex justify-between items-baseline">
                 <h3 :class="['font-semibold truncate', chatStore.activeReceiverId === user.id ? 'text-white' : 'text-gray-800 dark:text-gray-200']">
                     {{ user.username }}
                 </h3>
                 <span :class="['text-xs', chatStore.activeReceiverId === user.id ? 'text-amber-200' : 'text-gray-400 dark:text-gray-500']">{{ formatTime(user.lastMessageTime) }}</span>
             </div>
             <p :class="['text-sm truncate opacity-90', chatStore.activeReceiverId === user.id ? 'text-amber-100' : 'text-gray-500']">
                 {{ user.lastMessage || 'Click to start chatting...' }}
             </p>
          </div>
       </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useChatStore } from '../../stores/chat'
import { PlusIcon, MagnifyingGlassIcon } from '@heroicons/vue/24/outline'
import { formatTime } from '../../utils/date'

const chatStore = useChatStore()
</script>
