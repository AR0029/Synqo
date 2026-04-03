'use client'

import Link from 'next/link'
import { LayoutDashboard, CheckSquare, Settings, LogOut } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter, usePathname } from 'next/navigation'

export function Sidebar() {
  const router = useRouter()
  const pathname = usePathname()
  const supabase = createClient()

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  const links = [
    { href: '/dashboard', label: 'Projects', icon: LayoutDashboard },
    { href: '/settings', label: 'Settings', icon: Settings },
  ]

  return (
    <aside className="w-64 border-r border-white/5 bg-[#0D0D0E]/80 backdrop-blur-2xl flex flex-col h-screen fixed hidden md:flex z-50">
      <div className="p-8">
        <h2 className="text-2xl font-black tracking-tighter text-white">
          Synqo<span className="text-purple-500">.</span>
        </h2>
      </div>

      <nav className="flex-1 px-4 space-y-2 relative">
        {links.map((link) => {
          const isActive = pathname === link.href || pathname.startsWith(`${link.href}/`)
          return (
            <Link
              key={link.href}
              href={link.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                isActive
                  ? 'bg-white/10 text-white font-semibold'
                  : 'text-white/50 hover:bg-white/5 hover:text-white'
              }`}
            >
              <link.icon size={20} className={isActive ? 'text-purple-400' : ''} />
              {link.label}
            </Link>
          )
        })}
      </nav>

      <div className="p-4 border-t border-white/5">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 w-full text-left text-red-500/80 hover:bg-red-500/10 hover:text-red-500 rounded-xl transition"
        >
          <LogOut size={20} />
          Logout
        </button>
      </div>
    </aside>
  )
}
