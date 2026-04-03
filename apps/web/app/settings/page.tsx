'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Camera } from 'lucide-react'

export default function Settings() {
  const [email, setEmail] = useState('Loading...')
  const [fullName, setFullName] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    fetchProfile()
  }, [])

  const fetchProfile = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      setEmail(user.email || '')
      const { data } = await supabase.from('profiles').select('full_name').eq('id', user.id).single()
      if (data?.full_name) setFullName(data.full_name)
    }
    setLoading(false)
  }

  const saveProfile = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      await supabase.from('profiles').update({ full_name: fullName.trim() }).eq('id', user.id)
    }
    setSaving(false)
    alert('Profile saved securely!')
  }

  if (loading) {
    return <div className="flex justify-center p-20"><div className="w-8 h-8 rounded-full border-2 border-white/20 border-t-white animate-spin"></div></div>
  }

  return (
    <div className="animate-in fade-in duration-500 max-w-2xl mx-auto">
      <h1 className="text-4xl font-black tracking-tight mb-12">Settings</h1>

      <div className="flex justify-center mb-16">
        <div className="relative">
          <div className="w-32 h-32 rounded-full bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center shadow-[0_0_40px_rgba(139,92,246,0.3)]">
            <Camera size={40} className="text-white drop-shadow-md" />
          </div>
          <button className="absolute bottom-0 right-0 bg-white text-black p-3 rounded-full hover:scale-105 transition shadow-xl">
            <Camera size={18} />
          </button>
        </div>
      </div>

      <form onSubmit={saveProfile} className="space-y-8">
        <div>
          <label className="block text-xs font-bold text-white/50 tracking-widest mb-3">EMAIL ADDRESS</label>
          <div className="w-full bg-[#18181B] border border-white/5 text-white/50 px-5 py-4 rounded-xl cursor-not-allowed">
            {email}
          </div>
        </div>

        <div>
           <label className="block text-xs font-bold text-white/50 tracking-widest mb-3">FULL NAME</label>
           <input
             type="text"
             value={fullName}
             onChange={(e) => setFullName(e.target.value)}
             className="w-full bg-[#1C1C1F] border border-white/5 text-white px-5 py-4 rounded-xl focus:ring-2 focus:ring-purple-500 outline-none transition"
             placeholder="e.g. Satoshi Nakamoto"
           />
        </div>

        <button
          type="submit"
          disabled={saving}
          className="w-full bg-white text-black font-bold py-4 rounded-xl mt-8 hover:bg-neutral-200 transition shadow-[0_0_20px_rgba(255,255,255,0.1)]"
        >
          {saving ? 'Saving Profile...' : 'Save Profile'}
        </button>
      </form>

      <div className="mt-16 pt-8 border-t border-white/5 flex flex-col items-center justify-center opacity-60 hover:opacity-100 transition-opacity duration-300">
        <p className="text-sm font-medium tracking-wide bg-gradient-to-r from-purple-400 to-blue-400 bg-clip-text text-transparent">
          Made with passion by Aryan Chaudhary
        </p>
        <p className="text-[10px] text-white/30 mt-2 uppercase tracking-widest font-black">
          Synqo v1.0.0
        </p>
      </div>
    </div>
  )
}
