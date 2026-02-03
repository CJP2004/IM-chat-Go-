import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', redirect: '/chat' },
  { path: '/login', component: () => import('../views/Login.vue') },
  { path: '/register', component: () => import('../views/Register.vue') },
  { path: '/chat', component: () => import('../views/Chat.vue') },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
