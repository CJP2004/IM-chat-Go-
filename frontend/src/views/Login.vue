<template>
  <div class="flex min-h-screen items-center justify-center bg-gray-50 p-4">
    <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-xl border border-gray-100">
      <div class="flex justify-center mb-6">
          <div class="p-3 bg-amber-500 rounded-xl shadow-lg shadow-amber-500/30 text-white">
             <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8">
               <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
             </svg>
          </div>
      </div>
      <h2 class="mb-2 text-center text-3xl font-bold text-gray-800">Welcome Back</h2>
      <p class="mb-8 text-center text-gray-500">Sign in to continue to IM Chat</p>
      
      <form @submit.prevent="handleLogin" class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Username</label>
          <input v-model="username" type="text" class="block w-full rounded-xl bg-gray-50 border border-gray-200 px-4 py-3 text-gray-800 focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 outline-none transition placeholder-gray-400" placeholder="Enter your username" />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
          <input v-model="password" type="password" class="block w-full rounded-xl bg-gray-50 border border-gray-200 px-4 py-3 text-gray-800 focus:border-amber-500 focus:ring-2 focus:ring-amber-500/20 outline-none transition placeholder-gray-400" placeholder="••••••••" />
        </div>
        <button type="submit" class="w-full rounded-xl bg-amber-500 px-4 py-3 text-white hover:bg-amber-600 transition font-semibold shadow-lg shadow-amber-500/30">
          Sign In
        </button>
      </form>
      <p class="mt-6 text-center text-sm text-gray-500">
        Don't have an account? <router-link to="/register" class="text-amber-600 hover:text-amber-700 font-medium">Sign up</router-link>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import axios from 'axios'

import { useToastStore } from '../stores/toast'

const router = useRouter()
const userStore = useUserStore()
const toast = useToastStore()

const username = ref('')
const password = ref('')

const handleLogin = async () => {
  if (!username.value || !password.value) {
    toast.warning('Please fill in all fields')
    return
  }

  try {
    const res = await axios.post('http://localhost:2222/api/login', {
      username: username.value,
      password: password.value
    })
    
    userStore.setToken(res.data.data.token)
    userStore.setUser(res.data.data.user)
    
    toast.success(`Welcome back, ${res.data.data.user.username}!`)
    router.push('/chat')
  } catch (e: any) {
    console.error(e)
    const msg = e.response?.data?.message || 'Login failed'
    toast.error(msg)
  }
}
</script>
