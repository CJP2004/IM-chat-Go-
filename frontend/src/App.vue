<template>
  <ToastContainer />
  <router-view></router-view>
</template>

import { onMounted } from 'vue'
import ToastContainer from './components/common/ToastContainer.vue'
import { useSettingsStore } from './stores/settings'

const settingsStore = useSettingsStore()

onMounted(() => {
    // Apply saved theme on startup
    settingsStore.setTheme(settingsStore.theme)
})

<style>
/* Global styles if needed */
</style>
