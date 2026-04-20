'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Circle, ArrowRight } from 'lucide-react'
import { useRouter } from 'next/navigation'

export default function FocusHub() {
  const [tasks, setTasks] = useState<any[]>([])
  const [lists, setLists] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(true)
  
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    fetchData()
    const channel = supabase.channel('public:tasks-focus').on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'tasks' },
      () => fetchData()
    ).subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const fetchData = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return router.push('/login')

    const [{ data: taskData }, { data: listData }] = await Promise.all([
      supabase.from('tasks')
        .select('*')
        .eq('is_completed', false)
        .eq('priority', 'high')
        .order('created_at', { ascending: false }),
      supabase.from('lists').select('id, title')
    ])
      
    if (taskData) setTasks(taskData)
    if (listData) {
      const map: Record<string, string> = {}
      listData.forEach(l => { map[l.id] = l.title })
      setLists(map)
    }
    setLoading(false)
  }

  const toggleTask = async (e: React.MouseEvent, taskId: string) => {
    e.stopPropagation()
    setTasks(prev => prev.filter(t => t.id !== taskId))
    await supabase.from('tasks').update({ is_completed: true }).eq('id', taskId)
  }

  return (
    <div className="animate-in fade-in duration-500 max-w-4xl mx-auto px-4 sm:px-0">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 md:mb-12 mt-4 md:mt-0">
        <h1 className="text-3xl sm:text-4xl font-black tracking-tight">Focus Hub</h1>
        <p className="text-white/30 text-sm">High-priority tasks across all projects</p>
      </div>

      <div className="space-y-3 mb-8">
        {loading ? (
           <div className="flex justify-center p-12"><div className="w-8 h-8 rounded-full border-2 border-white/20 border-t-white animate-spin"></div></div>
        ) : tasks.length === 0 ? (
          <div className="text-center p-8 sm:p-16 border border-white/5 border-dashed rounded-3xl bg-white/[0.01]">
            <p className="text-4xl mb-4">✅</p>
            <p className="text-white/40 font-medium text-sm sm:text-base">All caught up! No urgent tasks.</p>
          </div>
        ) : (
          <div className="grid gap-2">
          {tasks.map(task => (
            <div 
              key={task.id} 
              onClick={() => router.push(`/list/${task.list_id}`)}
              className="group flex items-center justify-between p-3 sm:p-4 rounded-xl border border-white/5 transition-all gap-3 bg-[#18181B] hover:bg-[#1C1C1F] hover:border-white/10 cursor-pointer"
            >
              <div className="flex items-center gap-3 sm:gap-4 flex-1 min-w-0">
                <button 
                  onClick={(e) => toggleTask(e, task.id)}
                  className="p-1 shrink-0 rounded-full border border-white/20 text-transparent hover:border-purple-500/50 hover:bg-purple-500/10 transition-colors"
                >
                  <Circle size={18} className="sm:w-[20px] sm:h-[20px]" />
                </button>
                <div className="flex-1 min-w-0">
                  <span className="block text-base sm:text-lg font-medium text-white group-hover:text-white/80 truncate">
                    {task.title}
                  </span>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-[9px] sm:text-[10px] px-2 py-0.5 rounded border font-bold uppercase tracking-wider bg-red-500/10 text-red-500 border-red-500/20">
                      URGENT
                    </span>
                    {lists[task.list_id] && (
                      <span className="text-[11px] text-white/30 truncate">{lists[task.list_id]}</span>
                    )}
                  </div>
                </div>
              </div>
              <ArrowRight size={16} className="text-white/20 group-hover:text-white/50 transition-colors shrink-0" />
            </div>
          ))}
        </div>
        )}
      </div>
    </div>
  )
}
