'use client'

import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { useState } from 'react'
import { Layers, ArrowLeft } from 'lucide-react'
import Link from 'next/link'

export default function Register() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()
  const supabase = createClient()

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    
    // Using email authentication for simplicity (remember to disable confirmation in Supabase if needed for dev)
    const { error } = await supabase.auth.signUp({
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
    <div className="flex min-h-[100dvh] w-full items-center justify-center bg-[#0A0A0B] relative overflow-hidden font-sans">
      {/* Dynamic Ambient Glows */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-purple-600/20 blur-[150px] rounded-full pointer-events-none animate-pulse duration-[8000ms]" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] bg-blue-600/20 blur-[150px] rounded-full pointer-events-none animate-pulse duration-[10000ms]" style={{ animationDelay: '1s' }} />

      <Link href="/" className="absolute top-8 left-8 text-white/50 hover:text-white flex items-center gap-2 transition-colors z-20 font-medium">
        <ArrowLeft size={20} /> Back home
      </Link>
      
      <div className="w-full max-w-md p-8 sm:p-10 bg-white/[0.03] backdrop-blur-xl rounded-[32px] border border-white/10 shadow-[0_0_50px_rgba(0,0,0,0.5)] z-10 m-4 relative group">
        <div className="absolute inset-0 bg-gradient-to-br from-white/[0.05] to-transparent rounded-[32px] pointer-events-none"></div>
        
        <div className="relative mb-10 text-center flex flex-col items-center">
          <div className="mb-6 w-16 h-16 rounded-2xl bg-gradient-to-br from-purple-500 to-blue-500 shadow-lg flex items-center justify-center p-0.5">
            <div className="w-full h-full bg-[#0A0A0B] rounded-[14px] flex items-center justify-center">
              <Layers size={28} className="text-white" />
            </div>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight mb-2">Create Account</h1>
          <p className="text-white/40 text-lg">Join Synqo today.</p>
        </div>

        {error && <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-2xl text-red-400 text-sm font-medium animate-in slide-in-from-top-2">{error}</div>}

        <form onSubmit={handleRegister} className="space-y-5 relative">
          <div>
            <label className="block text-[11px] font-black text-white/40 tracking-[0.2em] mb-2 pl-2">EMAIL</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-black/40 border border-white/5 text-white rounded-2xl p-4 sm:p-5 focus:ring-2 focus:ring-purple-500/50 focus:border-purple-500/50 outline-none transition-all placeholder:text-white/20"
              placeholder="you@example.com"
            />
          </div>
          <div>
            <label className="block text-[11px] font-black text-white/40 tracking-[0.2em] mb-2 pl-2">PASSWORD</label>
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-black/40 border border-white/5 text-white rounded-2xl p-4 sm:p-5 focus:ring-2 focus:ring-purple-500/50 focus:border-purple-500/50 outline-none transition-all placeholder:text-white/20"
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-white text-black font-bold text-lg rounded-2xl py-4 sm:py-5 hover:bg-neutral-200 hover:scale-[1.02] shadow-[0_10px_30px_rgba(255,255,255,0.1)] active:scale-[0.98] disabled:opacity-50 disabled:scale-100 transition-all mt-8"
          >
            {loading ? 'Creating...' : 'Sign Up'}
          </button>
        </form>

        <p className="mt-8 text-center text-white/40 text-sm font-medium relative">
          Already have an account?{' '}
          <Link href="/login" className="text-white hover:text-purple-400 underline decoration-white/30 underline-offset-4 transition-colors">Log In</Link>
        </p>
      </div>
    </div>
  )
}
