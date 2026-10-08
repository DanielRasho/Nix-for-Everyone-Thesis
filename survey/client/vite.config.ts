import path from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // The API port lives in the server's .env (API_PORT). The browser always calls
  // relative /api/... URLs; in dev this proxy strips /api like nginx does in prod.
  const serverEnv = loadEnv(mode, path.resolve(import.meta.dirname, '../server'), '')
  const apiPort = serverEnv.API_PORT || '8080'

  return {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        '@': path.resolve(import.meta.dirname, './src'),
      },
    },
    server: {
      port: 3000,
      strictPort: true,
      proxy: {
        '/api': {
          target: `http://localhost:${apiPort}`,
          changeOrigin: true,
          rewrite: (p) => p.replace(/^\/api/, ''),
        },
      },
    },
  }
})
