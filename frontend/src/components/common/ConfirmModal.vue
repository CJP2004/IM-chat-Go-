<template>
  <Transition name="modal">
    <div v-show="isOpen" class="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="$emit('cancel')"></div>

      <!-- Modal Card -->
      <div class="relative bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden transform scale-100">
        <div class="p-6 text-center">
          <div class="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/30 mb-6">
            <template v-if="type === 'danger'">
                <ExclamationTriangleIcon class="h-8 w-8 text-red-600 dark:text-red-500" aria-hidden="true" />
            </template>
            <template v-else>
                <InformationCircleIcon class="h-8 w-8 text-amber-600 dark:text-amber-500" aria-hidden="true" />
            </template>
          </div>
          
          <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-2">{{ title }}</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400 mb-8">{{ message }}</p>

          <div class="flex space-x-3">
            <button 
              @click="$emit('cancel')"
              class="flex-1 py-2.5 px-4 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 rounded-xl font-medium transition focus:outline-none"
            >
              {{ cancelText }}
            </button>
            <button 
              @click="$emit('confirm')"
              :class="[
                  'flex-1 py-2.5 px-4 text-white rounded-xl font-medium transition shadow-lg focus:outline-none',
                  type === 'danger' ? 'bg-red-500 hover:bg-red-600 shadow-red-500/30' : 'bg-amber-500 hover:bg-amber-600 shadow-amber-500/30'
              ]"
            >
              {{ confirmText }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ExclamationTriangleIcon, InformationCircleIcon } from '@heroicons/vue/24/outline'

defineProps({
  isOpen: Boolean,
  title: {
      type: String,
      default: 'Are you sure?'
  },
  message: {
      type: String,
      default: 'This action cannot be undone.'
  },
  confirmText: {
      type: String,
      default: 'Confirm'
  },
  cancelText: {
      type: String,
      default: 'Cancel'
  },
  type: {
      type: String,
      default: 'danger' // 'danger' | 'info'
  }
})

defineEmits(['confirm', 'cancel'])
</script>

<style scoped>
/* Unified simple transition for perfect sync */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  will-change: opacity;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

/* Ensure the modal content scales in sync with the opacity fade */
.modal-enter-active .transform,
.modal-leave-active .transform {
  transition: transform 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  will-change: transform;
}

.modal-enter-from .transform {
  transform: scale(0.95);
}
.modal-leave-to .transform {
  transform: scale(0.95);
}
</style>
