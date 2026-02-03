<template>
  <div class="w-72 flex flex-col py-6 bg-white dark:bg-gray-900 border-r border-gray-100 dark:border-gray-800 h-full transition-colors duration-200">
    <!-- Logo / Brand -->
    <div class="px-8 mb-10 flex items-center space-x-3 text-gray-800 dark:text-gray-100">
        <ChatBubbleOvalLeftEllipsisIcon class="w-8 h-8 text-amber-500 fill-current" />
        <h1 class="text-2xl font-bold tracking-tight">Chatbox</h1>
    </div>

    <!-- Nav Items -->
    <nav class="flex-1 space-y-2 px-6">
      <div 
        v-for="item in navItems" 
        :key="item.value"
        @click="uiStore.setActiveTab(item.value as any)"
        :class="[
          'flex items-center space-x-4 p-4 rounded-2xl cursor-pointer transition-all duration-200 font-medium',
          uiStore.activeTab === item.value 
            ? 'bg-amber-500 text-white shadow-lg shadow-amber-500/30' 
            : 'text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-800'
        ]"
      >
        <component :is="item.icon" class="w-6 h-6" />
        <span class="text-base">{{ item.label }}</span>
        
        <!-- Optional Badge (Visual only) -->
        <span v-if="item.badge" class="ml-auto bg-red-500 text-white text-xs font-bold px-1.5 py-0.5 rounded-full">
            {{ item.badge }}
        </span>
      </div>
    </nav>

    <!-- Bottom User Profile -->
    <div class="px-6 mt-auto">
        <div class="flex items-center p-3 rounded-2xl hover:bg-gray-50 dark:hover:bg-gray-800 transition cursor-pointer group">
            <div class="relative" @click="triggerAvatarUpdate">
                <img 
                    :src="userStore.user?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${userStore.user?.username}`" 
                    class="w-12 h-12 rounded-full object-cover shadow-sm bg-gray-200 group-hover:ring-2 ring-amber-500 transition"
                />
                 <input type="file" ref="avatarInput" class="hidden" accept="image/*" @change="handleAvatarUpload" />
            </div>
            
            <div class="ml-4 flex-1">
                <h3 class="text-sm font-bold text-gray-900 dark:text-gray-100 leading-none">{{ userStore.user?.username || 'User' }}</h3>
                
                <!-- Tagline (Read-only, shows device info) -->
                <div class="text-xs text-amber-500 mt-1 truncate max-w-[120px] min-h-[1rem]" :title="userStore.user?.tagline || 'Unknown Device'">
                     {{ userStore.user?.tagline || 'Unknown Device' }}
                </div>
            </div>
        </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useUIStore } from '../../stores/ui'
import { useUserStore } from '../../stores/user'
import { useChatStore } from '../../stores/chat'
import axios from 'axios'
import { 
  ChatBubbleLeftRightIcon, 
  ChatBubbleOvalLeftEllipsisIcon,
  Squares2X2Icon,
  ChartBarIcon,
  FolderIcon,
  PhoneIcon,
  UserGroupIcon, 
  Cog6ToothIcon 
} from '@heroicons/vue/24/outline'

import { useToastStore } from '../../stores/toast'

const router = useRouter()
const uiStore = useUIStore()
const userStore = useUserStore()
const chatStore = useChatStore()
const toast = useToastStore()
const avatarInput = ref<HTMLInputElement | null>(null)


// Updating nav items to match Image 1
const navItems = [
  { label: 'Dashboard', value: 'dashboard', icon: Squares2X2Icon },
  { label: 'Analytics', value: 'analytics', icon: ChartBarIcon },
  { label: 'Files', value: 'files', icon: FolderIcon },
  { label: 'Call', value: 'call', icon: PhoneIcon },
  { label: 'Messages', value: 'chats', icon: ChatBubbleLeftRightIcon, badge: 4 }, // Main functional tab
  { label: 'Community', value: 'community', icon: UserGroupIcon },
  { label: 'Settings', value: 'settings', icon: Cog6ToothIcon },
]

// Determine if we should default to 'chats' if current active tab is not in list (handling legacy states)
if (!navItems.find(i => i.value === uiStore.activeTab)) {
    uiStore.setActiveTab('chats')
}

const triggerAvatarUpdate = () => {
    avatarInput.value?.click()
}

const handleAvatarUpload = async (event: any) => {
    const file = event.target.files[0]
    if (!file) return

    try {
        const url = await chatStore.uploadImage(file)
        if (userStore.user) {
             const res = await axios.put(`http://localhost:2222/api/user/avatar?userId=${userStore.user.id}`, {
                 avatar: url
             })
             userStore.user.avatar = res.data.data.avatar
             userStore.setUser(userStore.user) // Trigger update
             toast.success('Avatar updated successfully')
        }
    } catch (e) {
        console.error("Avatar update failed", e)
        toast.error('Failed to update avatar')
    }
}

const logout = () => {
  userStore.logout()
  router.push('/login')
}
</script>
