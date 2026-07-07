/// <reference types="vite/client" />

interface Window {
  __APP_CONFIG__?: {
    VITE_AZURE_CLIENT_ID?: string
    VITE_AZURE_AUTHORITY?: string
    VITE_AZURE_REDIRECT_URI?: string
  }
}

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}
