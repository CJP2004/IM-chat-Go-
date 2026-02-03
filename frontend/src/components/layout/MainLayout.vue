<template>
  <div class="flex h-screen w-screen overflow-hidden bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 transition-colors duration-200">
      <MainNav />
      <ConversationList v-if="uiStore.activeTab === 'chats'" />
      <SettingsPanel v-else-if="uiStore.activeTab === 'settings'" />
      <ChatWindow />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from 'vue'
import { useUIStore } from '../../stores/ui'
import { useUserStore } from '../../stores/user'
import { useChatStore } from '../../stores/chat'
import MainNav from '../sidebar/MainNav.vue'
import ConversationList from '../sidebar/ConversationList.vue'
import SettingsPanel from '../settings/SettingsPanel.vue'
import ChatWindow from '../chat/ChatWindow.vue'

const uiStore = useUIStore()
const userStore = useUserStore()
const chatStore = useChatStore()

onMounted(() => {
    // Initialize data
    chatStore.connect()
    chatStore.fetchUsers()
})

onUnmounted(() => {
    chatStore.disconnect()
})
</script>
