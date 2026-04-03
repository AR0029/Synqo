import Link from 'next/link'
import { Layers, ArrowRight, CheckCircle2 } from 'lucide-react'

export default function Home() {
  return (
    <div className="min-h-screen bg-[#0A0A0B] text-white overflow-hidden relative flex flex-col justify-center items-center font-sans tracking-tight">
      {/* Dynamic Ambient Background Elements */}
      <div className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] bg-purple-600/15 blur-[150px] rounded-full pointer-events-none animate-pulse duration-[10000ms]" />
      <div className="absolute bottom-[-20%] right-[-10%] w-[600px] h-[600px] bg-blue-600/15 blur-[150px] rounded-full pointer-events-none animate-pulse duration-[12000ms]" style={{ animationDelay: '2s' }} />

      {/* Grid Pattern overlay for tech aesthetic */}
      <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-20 mix-blend-overlay pointer-events-none"></div>

      <main className="z-10 text-center px-6 max-w-4xl mx-auto flex flex-col items-center animate-in fade-in slide-in-from-bottom-12 duration-1000">
        
        {/* Glow Logo Hero */}
        <div className="mb-8 w-24 h-24 rounded-[32px] bg-gradient-to-br from-purple-500 to-blue-500 shadow-[0_0_60px_rgba(139,92,246,0.3)] flex items-center justify-center p-1 relative group">
          <div className="absolute inset-0 bg-gradient-to-br from-purple-500 to-blue-500 rounded-[32px] blur-xl opacity-50 group-hover:opacity-100 transition-opacity duration-500"></div>
          <div className="w-full h-full bg-[#0D0D0E] rounded-[28px] flex items-center justify-center relative z-10">
            <Layers size={44} className="text-white drop-shadow-[0_0_15px_rgba(255,255,255,0.5)]" />
          </div>
        </div>

        <h1 className="text-5xl md:text-8xl font-black tracking-tighter mb-6 bg-clip-text text-transparent bg-gradient-to-b from-white to-white/60 leading-tight">
          Sync your work.<br/>Master your time.
        </h1>
        
        <p className="text-lg md:text-2xl text-white/50 mb-12 max-w-2xl font-light leading-relaxed">
          Synqo is the ultimate cross-platform collaborative workspace. Real-time sync, powerful priority tags, and a stunning interface designed for modern professionals.
        </p>

        <div className="flex flex-col sm:flex-row gap-5 w-full sm:w-auto">
          <Link 
            href="/register" 
            className="flex items-center justify-center gap-2 group bg-white text-black px-10 py-5 rounded-2xl font-bold text-lg hover:scale-105 transition-all shadow-[0_0_40px_rgba(255,255,255,0.15)]"
          >
            Get Started Free <ArrowRight className="group-hover:translate-x-1 transition-transform" size={20} />
          </Link>
          <Link 
            href="/login" 
            className="flex items-center justify-center px-10 py-5 rounded-2xl font-bold text-lg bg-white/5 hover:bg-white/10 border border-white/10 transition-all text-white backdrop-blur-md"
          >
            Log In
          </Link>
        </div>

        {/* Feature badges */}
        <div className="mt-24 grid grid-cols-1 sm:grid-cols-3 gap-6 text-sm text-white/40 font-medium">
          <div className="flex items-center justify-center gap-3 bg-white/5 px-6 py-3 rounded-2xl border border-white/10 backdrop-blur-sm">
            <CheckCircle2 size={18} className="text-purple-400" /> Real-time Postgres
          </div>
          <div className="flex items-center justify-center gap-3 bg-white/5 px-6 py-3 rounded-2xl border border-white/10 backdrop-blur-sm">
            <CheckCircle2 size={18} className="text-blue-400" /> Cross-Platform Sync
          </div>
          <div className="flex items-center justify-center gap-3 bg-white/5 px-6 py-3 rounded-2xl border border-white/10 backdrop-blur-sm">
            <CheckCircle2 size={18} className="text-teal-400" /> Bank-grade Security
          </div>
        </div>
      </main>
    </div>
  )
}
