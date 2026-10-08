/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Microsoft Clarity project id. Unset = Clarity is not loaded. */
  readonly VITE_CLARITY_PROJECT_ID?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
