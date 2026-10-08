import { CopyIcon, TriangleAlertIcon } from 'lucide-react'
import { toast } from 'sonner'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

async function copy(text: string) {
  try {
    await navigator.clipboard.writeText(text)
    toast.success('Contraseña copiada')
  } catch {
    toast.error('No se pudo copiar', { description: 'Selecciona la contraseña y cópiala manualmente.' })
  }
}

/** A generated password, shown only once (the server only keeps its hash). */
export function PasswordReveal({ username, password }: { username: string; password: string }) {
  return (
    <div className="grid gap-4">
      <Alert variant="destructive">
        <TriangleAlertIcon />
        <AlertTitle>Esta contraseña no se volverá a mostrar</AlertTitle>
        <AlertDescription>
          Cópiala y entrégasela a {username} ahora. Si se pierde, tendrás que regenerarla.
        </AlertDescription>
      </Alert>
      <div className="grid gap-2">
        <Label htmlFor="generated-user">Usuario</Label>
        <Input id="generated-user" readOnly value={username} className="font-mono" />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="generated-password">Contraseña</Label>
        <div className="flex gap-2">
          <Input
            id="generated-password"
            readOnly
            value={password}
            onFocus={(e) => e.currentTarget.select()}
            className="font-mono"
          />
          <Button variant="outline" onClick={() => void copy(password)}>
            <CopyIcon />
            Copiar
          </Button>
        </div>
      </div>
    </div>
  )
}
