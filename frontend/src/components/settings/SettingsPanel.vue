<template>
  <div class="w-80 h-full flex flex-col bg-white dark:bg-gray-900 border-r border-gray-100 dark:border-gray-800 transition-colors duration-200">
    <!-- Header -->
    <div class="p-4 flex items-center justify-between mb-2">
      <h2 class="text-xl font-bold text-gray-800 dark:text-white">Settings</h2>
    </div>

    <!-- Scrollable Content -->
    <div class="flex-1 overflow-y-auto px-4 pb-4 space-y-14">
      
      <!-- Appearance -->
      <section>
        <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Appearance</h3>
        
        <!-- Theme -->
        <div class="flex items-center justify-between mb-6">
            <span class="text-gray-700 font-medium">Dark Mode</span>
            <button 
                @click="toggleTheme"
                :class="[
                    'w-12 h-6 rounded-full p-1 transition-colors duration-200 ease-in-out',
                    settingsStore.theme === 'dark' ? 'bg-amber-500' : 'bg-gray-200'
                ]"
            >
                <div :class="[
                    'w-4 h-4 bg-white rounded-full shadow-md transform transition duration-200 ease-in-out',
                    settingsStore.theme === 'dark' ? 'translate-x-6' : 'translate-x-0'
                ]"></div>
            </button>
        </div>

        <!-- Font Size -->
        <div class="mb-6">
            <div class="flex justify-between mb-2">
                <span class="text-gray-700 dark:text-gray-200 font-medium">Font Size</span>
                <span class="text-xs text-gray-500 dark:text-gray-300 bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded">{{ settingsStore.fontSize }}</span>
            </div>
            <input 
                type="range" 
                min="0" 
                max="2" 
                step="1"
                :value="fontSizeValue"
                @input="handleFontSizeChange"
                class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer accent-amber-500"
            />
            <div class="flex justify-between text-xs text-gray-400 mt-1">
                <span>Small</span>
                <span>Normal</span>
                <span>Large</span>
            </div>
        </div>


      </section>

      <section>
        <h3 class="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">About</h3>
        <div class="text-center py-2">
            <div class="inline-flex p-3 bg-amber-50 dark:bg-gray-800 rounded-full mb-3">
                <ChatBubbleOvalLeftEllipsisIcon class="w-8 h-8 text-amber-500" />
            </div>
            <h4 class="font-bold text-gray-800 dark:text-white">IM Chat</h4>
            <p class="text-xs text-gray-500 dark:text-gray-400">Version 1.0.0</p>
            <a href="#" class="text-xs text-amber-500 hover:underline mt-2 inline-block">Check for updates</a>
        </div>
      </section>

      <!-- System Actions -->
      <section>
        <h3 class="text-xs font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-3">System</h3>
        <div class="flex space-x-3">
             <button 
                @click="clearCache"
                class="flex-1 flex items-center justify-center py-2.5 rounded-xl border border-gray-200 dark:border-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-white transition"
            >
                <TrashIcon class="w-4 h-4 mr-2" />
                Clear Cache
            </button>
            <button 
                @click="showLogoutModal = true"
                class="flex-1 flex items-center justify-center py-2.5 rounded-xl bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 font-medium hover:bg-red-100 dark:hover:bg-red-900/30 transition shadow-sm"
            >
                <ArrowRightOnRectangleIcon class="w-4 h-4 mr-2" />
                Log Out
            </button>
        </div>
      </section>

      <ConfirmModal 
        :isOpen="showLogoutModal"
        title="Log Out?"
        message="Are you sure you want to log out of your account?"
        confirmText="Log Out"
        @confirm="confirmLogout"
        @cancel="showLogoutModal = false"
      />

    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useSettingsStore } from '../../stores/settings'
import { useUserStore } from '../../stores/user'
import { useToastStore } from '../../stores/toast'
import { TrashIcon, ArrowRightOnRectangleIcon, ChatBubbleOvalLeftEllipsisIcon } from '@heroicons/vue/24/outline'

import ConfirmModal from '../common/ConfirmModal.vue'

const router = useRouter()
const settingsStore = useSettingsStore()
const userStore = useUserStore()
const toast = useToastStore()
const showLogoutModal = ref(false)

const wallpapers = ['#fef3c7', '#dcfce7', '#dbeafe', '#f3f4f6', '#fae8ff', '#ffe4e6'] // Light presets

const toggleTheme = () => {
    const newTheme = settingsStore.theme === 'dark' ? 'light' : 'dark'
    settingsStore.setTheme(newTheme)
    toast.info(`Switched to ${newTheme} mode`)
}

const fontSizeValue = computed(() => {
    switch(settingsStore.fontSize) {
        case 'small': return 0
        case 'normal': return 1
        case 'large': return 2
        default: return 1
    }
})

const handleFontSizeChange = (e: Event) => {
    const val = parseInt((e.target as HTMLInputElement).value)
    const sizes: ('small' | 'normal' | 'large')[] = ['small', 'normal', 'large']
    settingsStore.setFontSize(sizes[val])
}

const setWallpaper = (val: string) => {
    settingsStore.setWallpaper(val)
}

const clearCache = () => {
    settingsStore.clearCache()
    toast.success('Cache cleared successfully')
}

const confirmLogout = () => {
    userStore.logout()
    toast.info('Logged out successfully')
    showLogoutModal.value = false
    router.push('/login')
}
</script>
