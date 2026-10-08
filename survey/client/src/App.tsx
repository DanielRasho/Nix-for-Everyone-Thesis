import { lazy, Suspense } from 'react'
import { QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router'
import { AppShell } from '@/components/app-shell'
import { LoadingState } from '@/components/page-state'
import { RequireRole } from '@/components/require-role'
import { ThemeProvider } from '@/components/theme-provider'
import { Toaster } from '@/components/ui/sonner'
import { queryClient } from '@/lib/query-client'
import { LoginPage } from '@/pages/login-page'
import { RoadmapPage } from '@/pages/roadmap-page'

// Split: Markdown/question renderers and the admin panel are only loaded when needed.
const StepPage = lazy(() => import('@/pages/step-page').then((m) => ({ default: m.StepPage })))
const AdminPage = lazy(() => import('@/pages/admin-page').then((m) => ({ default: m.AdminPage })))

export default function App() {
  return (
    <ThemeProvider>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route
              element={
                <RequireRole role="participant">
                  <AppShell />
                </RequireRole>
              }
            >
              <Route index element={<RoadmapPage />} />
              <Route
                path="steps/:stepId"
                element={
                  <Suspense fallback={<LoadingState />}>
                    <StepPage />
                  </Suspense>
                }
              />
            </Route>
            <Route
              path="admin"
              element={
                <RequireRole role="admin">
                  <AppShell />
                </RequireRole>
              }
            >
              <Route
                index
                element={
                  <Suspense fallback={<LoadingState />}>
                    <AdminPage />
                  </Suspense>
                }
              />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
        <Toaster richColors closeButton position="top-center" />
      </QueryClientProvider>
    </ThemeProvider>
  )
}
