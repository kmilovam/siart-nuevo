'use client'
import { useState } from 'react'

export default function LoginPage() {
  const [user, setUser] = useState('')
  const [pass, setPass] = useState('')
  const [err, setErr] = useState('')

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user, pass })
    })
    if (res.ok) {
      document.cookie = 'loggedIn=true;path=/'
      window.location.href = '/'
    } else {
      setErr('Usuario o contraseña incorrectos')
    }
  }

  return (
    <div className="login-page">
      <form onSubmit={onSubmit} className="login-form">
        <h2>Acceso SIART</h2>
        <input
          type="text"
          placeholder="Usuario"
          value={user}
          onChange={e => setUser(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Contraseña"
          value={pass}
          onChange={e => setPass(e.target.value)}
          required
        />
        <button type="submit">Entrar</button>
        {err && <p className="error-text">{err}</p>}
      </form>
      <style jsx>{`
        /* estilos… */
      `}</style>
    </div>
  )
}
