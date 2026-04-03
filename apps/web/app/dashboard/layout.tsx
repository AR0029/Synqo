import { Sidebar } from '@/components/sidebar'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-[#0D0D0E] text-white overflow-hidden">
      <Sidebar />
      <main className="flex-1 ml-0 md:ml-64 overflow-y-auto relative">
        <div className="absolute top-[-150px] right-[-150px] w-[500px] h-[500px] bg-purple-600/10 blur-[150px] rounded-full pointer-events-none" />
        <div className="absolute bottom-[-150px] left-[-50px] w-[500px] h-[500px] bg-blue-600/10 blur-[150px] rounded-full pointer-events-none" />
        <div className="p-8 md:p-12 relative z-10 max-w-7xl mx-auto">
          {children}
        </div>
      </main>
    </div>
  )
}
