'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Circle } from 'lucide-react'
import { useRouter } from 'next/navigation'

export default function FocusHub() {
  const [tasks, setTasks] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    fetchData()
    const channel = supabase.channel('public:tasks-focus').on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'tasks', filter: "is_completed=eq.false" },
      () => fetchData()
    ).subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const fetchData = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return router.push('/login')

    const { data: taskData } = await supabase.from('tasks')
      .select('*')
      .eq('is_completed', false)
      .eq('priority', 'high')
      .order('created_at', { ascending: false })
      
    if (taskData) setTasks(taskData)
    setLoading(false)
  }

  const toggleTask = async (taskId: string) => {
    setTasks(prev => prev.filter(t => t.id !== taskId))
    await supabase.from('tasks').update({ is_completed: true }).eq('id', taskId)
  }

  return (
    <div className="animate-in fade-in duration-500 max-w-4xl mx-auto px-4 sm:px-0">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 md:mb-12 mt-4 md:mt-0">
        <h1 className="text-3xl sm:text-4xl font-black tracking-tight">Focus Hub</h1>
      </div>

      <div className="space-y-3 mb-8">
        {loading ? (
           <div className="flex justify-center p-12"><div className="w-8 h-8 rounded-full border-2 border-white/20 border-t-white animate-spin"></div></div>
        ) : tasks.length === 0 ? (
          <div className="text-center p-8 sm:p-16 border border-white/5 border-dashed rounded-3xl bg-white/[0.01]">
            <p className="text-white/40 mb-6 font-medium text-sm sm:text-base">All caught up! No urgent tasks.</p>
          </div>
        ) : (
          <div className="grid gap-2">
          {tasks.map(task => (
            <div 
              key={task.id} 
              className="group flex flex-col sm:flex-row sm:items-center justify-between p-3 sm:p-4 rounded-xl border border-white/5 transition-all gap-3 bg-[#18181B] hover:bg-[#1C1C1F]"
            >
              <div className="flex justify-between items-center w-full">
                <div className="flex items-center gap-3 sm:gap-4 cursor-pointer flex-1" onClick={() => toggleTask(task.id)}>
                  <button className="p-1 shrink-0 rounded-full border border-white/20 text-transparent hover:border-purple-500/50 hover:bg-purple-500/10 transition-colors">
                    <Circle size={18} className="sm:w-[20px] sm:h-[20px]" />
                  </button>
                  <span className="text-base sm:text-lg font-medium transition-all break-words line-clamp-2 text-white group-hover:text-white/80">
                    {task.title}
                  </span>
                  
                  <span className="text-[9px] sm:text-[10px] px-2 py-1 rounded border font-bold uppercase tracking-wider shrink-0 bg-red-500/10 text-red-500 border-red-500/20">
                    URGENT
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
        )}
      </div>
    </div>
  )
}
