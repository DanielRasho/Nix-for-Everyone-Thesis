import { useEffect, useState } from 'react'
import { CheckIcon, CopyIcon } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

/** Copies `text` to the clipboard, showing a check for a moment. */
export function CopyButton({ text, className }: { text: string; className?: string }) {
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    if (!copied) return
    const timer = setTimeout(() => setCopied(false), 2000)
    return () => clearTimeout(timer)
  }, [copied])

  const copy = async () => {
    try {
      // Undefined outside a secure context (plain http), which throws here too.
      await navigator.clipboard.writeText(text)
      setCopied(true)
    } catch (err) {
      console.error('copy failed', err)
      toast.error('No se pudo copiar. Selecciona el código y cópialo manualmente.')
    }
  }

  const label = copied ? 'Copiado' : 'Copiar código'
  return (
    <Button
      type="button"
      variant="outline"
      size="icon-sm"
      className={cn('bg-background/80 backdrop-blur-sm', className)}
      onClick={() => void copy()}
      aria-label={label}
      title={label}
    >
      {copied ? <CheckIcon className="text-success" /> : <CopyIcon />}
    </Button>
  )
}
