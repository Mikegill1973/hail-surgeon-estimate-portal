'use client';
import { useState } from 'react';
import { supabase } from '../../lib/supabase';
export default function Login(){const[email,setEmail]=useState('');const[pw,setPw]=useState('');const[msg,setMsg]=useState('');
async function signIn(){const {error}=await supabase.auth.signInWithPassword({email,password:pw});setMsg(error?error.message:'Logged in. Go to /dashboard');}
return <div className='card'><h2>Login</h2><input placeholder='email' value={email} onChange={e=>setEmail(e.target.value)}/><input type='password' placeholder='password' value={pw} onChange={e=>setPw(e.target.value)}/><button onClick={signIn}>Login</button><p>{msg}</p></div>}
