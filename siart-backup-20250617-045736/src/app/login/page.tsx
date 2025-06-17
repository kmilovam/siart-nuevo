'use client';
import { useState } from 'react';

export default function LoginPage() {
  const [user, setUser] = useState('');
  const [pass, setPass] = useState('');
  const [error, setError] = useState('');

  const onSubmit = async (e) => {
    e.preventDefault();
    const res = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user, pass }),
    });
    if (res.ok) window.location.href = '/';
    else setError('Usuario o contraseña incorrectos');
  };

  return (
    <div className="login-page">
      <form onSubmit={onSubmit} className="login-form">
        <h2>Acceso SIART</h2>
        <input type="text" placeholder="Usuario" value={user}
          onChange={e => setUser(e.target.value)} required/>
        <input type="password" placeholder="Contraseña" value={pass}
          onChange={e => setPass(e.target.value)} required/>
        <button type="submit">Entrar</button>
        {error && <p className="error-text">{error}</p>}
      </form>
      <style jsx>{`
        .login-page {
          display:flex;align-items:center;justify-content:center;
          min-height:100vh;
          background:url('/images/drone-background.jpg')center/cover no-repeat;
        }
        .login-form {
          background:rgba(0,0,0,0.6);padding:2rem;
          border-radius:10px;border:1px solid #004d26;color:white;
        }
        .login-form h2{color:#00cc66;margin-bottom:1rem;}
        .login-form input, .login-form button {
          width:100%;margin-bottom:1rem;padding:.5rem;
          border-radius:5px;border:none;
        }
        .login-form button {
          background:#004d26;color:white;cursor:pointer;
        }
        .error-text{color:#ff4444;}
      `}</style>
    </div>
  );
}
