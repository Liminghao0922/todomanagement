import { PublicClientApplication, Configuration, BrowserCacheLocation } from '@azure/msal-browser'

const runtimeConfig = window.__APP_CONFIG__ ?? {}
const defaultRedirectUri = window.location.origin

const getConfigValue = (runtimeValue: string | undefined, buildValue: string | undefined, fallback: string) =>
  runtimeValue || buildValue || fallback

// MSAL 配置 - 需要替换为实际的 Azure Entra ID 配置
export const msalConfig: Configuration = {
  auth: {
    clientId: getConfigValue(
      runtimeConfig.VITE_AZURE_CLIENT_ID,
      import.meta.env.VITE_AZURE_CLIENT_ID,
      '00000000-0000-0000-0000-000000000000'
    ),
    authority: getConfigValue(
      runtimeConfig.VITE_AZURE_AUTHORITY,
      import.meta.env.VITE_AZURE_AUTHORITY,
      'https://login.microsoftonline.com/common'
    ),
    redirectUri: getConfigValue(
      runtimeConfig.VITE_AZURE_REDIRECT_URI,
      import.meta.env.VITE_AZURE_REDIRECT_URI,
      defaultRedirectUri
    ),
    postLogoutRedirectUri: '/',
  },
  cache: {
    cacheLocation: BrowserCacheLocation.LocalStorage,
    storeAuthStateInCookie: false,
  },
  system: {
    loggerOptions: {
      loggerCallback: () => {}, // 禁用日志输出
    },
  },
}

// 请求作用域
export const loginRequest = {
  scopes: ['User.Read'],
}

// 创建 MSAL 实例
export const pca = new PublicClientApplication(msalConfig)
