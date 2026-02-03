<template>
  <div class="fixed top-4 left-1/2 transform -translate-x-1/2 z-50 flex flex-col space-y-2 pointer-events-none">
    <TransitionGroup name="toast">
      <div 
        v-for="toast in toastStore.toasts" 
        :key="toast.id"
        :class="[
            'pointer-events-auto flex items-center px-4 py-3 rounded-xl shadow-lg border backdrop-blur-sm min-w-[300px] max-w-md transition-all duration-300',
            toast.type === 'success' ? 'bg-green-50/90 border-green-200 text-green-700' :
            toast.type === 'error' ? 'bg-red-50/90 border-red-200 text-red-700' :
            toast.type === 'warning' ? 'bg-amber-50/90 border-amber-200 text-amber-700' :
            'bg-blue-50/90 border-blue-200 text-blue-700'
        ]"
      >
        <!-- Icons -->
        <CheckCircleIcon v-if="toast.type === 'success'" class="w-5 h-5 mr-3 flex-shrink-0" />
        <XCircleIcon v-if="toast.type === 'error'" class="w-5 h-5 mr-3 flex-shrink-0" />
        <ExclamationTriangleIcon v-if="toast.type === 'warning'" class="w-5 h-5 mr-3 flex-shrink-0" />
        <InformationCircleIcon v-if="toast.type === 'info'" class="w-5 h-5 mr-3 flex-shrink-0" />

        <span class="text-sm font-medium">{{ toast.message }}</span>
        
        <button @click="toastStore.remove(toast.id)" class="ml-auto text-current opacity-60 hover:opacity-100 transition p-1">
            <XMarkIcon class="w-4 h-4" />
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup lang="ts">
import { useToastStore } from '../../stores/toast'
import { 
    CheckCircleIcon, 
    XCircleIcon, 
    ExclamationTriangleIcon, 
    InformationCircleIcon,
    XMarkIcon
} from '@heroicons/vue/24/outline'

const toastStore = useToastStore()
</script>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.4s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateY(-20px) scale(0.9);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>
