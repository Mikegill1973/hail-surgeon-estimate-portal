'use client';
import { useState } from 'react';
import { createClient } from '@/lib/supabase';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');
  const login = async () => {
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setMessage(error?.message ?? 'Logged in');
  };
  return <div className="card"><h2>Login</h2><input placeholder="Email" value={email} onChange={(e)=>setEmail(e.target.value)} /><input type="password" placeholder="Password" value={password} onChange={(e)=>setPassword(e.target.value)} /><button onClick={login}>Login</button><p>{message}</p></div>;
}
