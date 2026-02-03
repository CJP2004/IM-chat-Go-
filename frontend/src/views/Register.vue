<template>
  <div class="flex min-h-screen items-center justify-center bg-gray-50 p-4">
    <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl border border-gray-100">
      <div class="flex justify-center mb-6">
          <div class="p-3 bg-amber-500 rounded-xl shadow-lg shadow-amber-500/30 text-white">
             <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8">
               <path stroke-linecap="round" stroke-linejoin="round" d="M19 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zM4 19.235v-.11a6.375 6.375 0 0112.75 0v.109A12.318 12.318 0 0110.374 21c-2.331 0-4.512-.645-6.374-1.766z" />
             </svg>
          </div>
      </div>
      <h2 class="mb-2 text-center text-3xl font-bold text-gray-800">Create Account</h2>
      <p class="mb-8 text-center text-gray-500">Join us and start chatting today</p>
      
      <form @submit.prevent="handleRegister" class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
          <input v-model="username" type="text" class="block w-full rounded-xl bg-gray-50 border border-gray-200 px-4 py-3 text-gray-800 focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 outline-none transition placeholder-gray-400" placeholder="Choose a username" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
          <input v-model="password" type="password" class="block w-full rounded-xl bg-gray-50 border border-gray-200 px-4 py-3 text-gray-800 focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 outline-none transition placeholder-gray-400" placeholder="Create a password" />
        </div>
        <button type="submit" class="w-full rounded-xl bg-amber-500 px-4 py-3 text-white hover:bg-amber-600 transition font-semibold shadow-lg shadow-amber-500/30">
          Sign Up
        </button>
      </form>
      <p class="mt-6 text-center text-sm text-gray-500">
        Already have an account? <router-link to="/login" class="text-amber-600 hover:text-amber-700 font-medium">Sign in</router-link>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

import { useToastStore } from '../stores/toast'

const router = useRouter()
const toast = useToastStore()

const username = ref('')
const password = ref('')

const handleRegister = async () => {
  if (!username.value || !password.value) {
     toast.warning('Please fill in all fields')
     return
  }

  try {
    await axios.post('http://localhost:2222/api/register', {
      username: username.value,
      password: password.value
    })
    toast.success('Registration successful! Please login.')
    router.push('/login')
  } catch (e: any) {
    const msg = e.response?.data?.message || 'Registration failed'
    toast.error(msg)
  }
}
</script>
