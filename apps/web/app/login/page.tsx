'use client'

import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setError(error.message)
      setLoading(false)
    } else {
      router.push('/dashboard')
      router.refresh()
    }
  }

  return (
    <div className="flex h-screen w-full items-center justify-center bg-[#0D0D0E] relative overflow-hidden">
      {/* Ambient Glow */}
      <div className="absolute top-[-100px] right-[-100px] w-96 h-96 bg-blue-600/10 blur-[120px] rounded-full pointer-events-none" />
      <div className="absolute bottom-[-100px] left-[-100px] w-96 h-96 bg-purple-600/10 blur-[120px] rounded-full pointer-events-none" />
      
      <div className="w-full max-w-sm p-8 bg-[#18181B] rounded-2xl border border-white/5 shadow-2xl z-10">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">Welcome Back</h1>
          <p className="text-white/40">Log in to Synqo to manage your tasks.</p>
        </div>

        {error && <div className="mb-4 p-3 bg-red-500/10 border border-red-500/20 rounded-xl text-red-400 text-sm">{error}</div>}

        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-white/50 tracking-wider mb-2">EMAIL</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-[#1C1C1F] border-none text-white rounded-xl p-4 focus:ring-2 focus:ring-purple-500 outline-none transition"
              placeholder="you@example.com"
            />
          </div>
          <div>
            <label className="block text-xs font-bold text-white/50 tracking-wider mb-2">PASSWORD</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-[#1C1C1F] border-none text-white rounded-xl p-4 focus:ring-2 focus:ring-purple-500 outline-none transition"
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-white text-black font-bold rounded-xl py-4 hover:bg-neutral-200 transition mt-6"
          >
            {loading ? 'Entering...' : 'Login'}
          </button>
        </form>

        <p className="mt-6 text-center text-white/40 text-sm">
          Don't have an account?{' '}
          <a href="/register" className="text-white hover:underline font-medium">Register</a>
        </p>
      </div>
    </div>
  )
}
