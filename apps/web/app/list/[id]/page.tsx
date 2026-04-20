'use client'

import { useState, useEffect, useMemo, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { ArrowLeft, CheckCircle2, Circle, Plus, Trash2, Users, Edit2, Share2 } from 'lucide-react'
import { useRouter } from 'next/navigation'

export default function ListDetail({ params }: { params: { id: string } }) {
  const [tasks, setTasks] = useState<any[]>([])
  const [listName, setListName] = useState('Loading...')
  const [isShared, setIsShared] = useState(false)
  const [newTaskTitle, setNewTaskTitle] = useState('')
  const [newTaskPriority, setNewTaskPriority] = useState('medium')
  const [isCreating, setIsCreating] = useState(false)
  const [editingTaskId, setEditingTaskId] = useState<string | null>(null)
  const [editTaskTitle, setEditTaskTitle] = useState('')
  const [editTaskPriority, setEditTaskPriority] = useState('medium')
  const [loading, setLoading] = useState(true)

  // Sharing State
  const [isSharing, setIsSharing] = useState(false)
  const [shareEmail, setShareEmail] = useState('')
  const [shareLoading, setShareLoading] = useState(false)
  
  // Stable supabase client — never re-created on re-render
  const supabase = useMemo(() => createClient(), [])
  const router = useRouter()
  // Keep a ref so the channel callback always has the latest fetch function
  const fetchRef = useRef<() => Promise<void>>()

  const fetchData = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return router.push('/login')

    const { data: listData } = await supabase.from('lists').select('title, is_shared').eq('id', params.id).single()
    if (listData) {
      setListName(listData.title)
      setIsShared(listData.is_shared)
    }

    const { data: taskData } = await supabase.from('tasks').select('*').eq('list_id', params.id).order('created_at', { ascending: false })
    if (taskData) setTasks(taskData)

    setLoading(false)
  }

  // Keep ref current
  fetchRef.current = fetchData

  useEffect(() => {
    // Initial load
    fetchRef.current?.()

    // Single stable channel for this list
    const channel = supabase
      .channel(`list-detail-${params.id}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'tasks', filter: `list_id=eq.${params.id}` },
        () => { fetchRef.current?.() }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          console.log(`Realtime subscribed for list ${params.id}`)
        }
      })

    return () => { supabase.removeChannel(channel) }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [params.id])


  const sortTasks = (tasksList: any[]) => {
    const priorityScore = (p: string) => p === 'high' ? 3 : p === 'medium' ? 2 : p === 'low' ? 1 : 0;
    
    return [...tasksList].sort((a, b) => {
      if (a.is_completed !== b.is_completed) return a.is_completed ? 1 : -1;
      
      const pA = priorityScore(a.priority);
      const pB = priorityScore(b.priority);
      if (pA !== pB) return pB - pA;
      
      const dateA = new Date(a.created_at || 0).getTime();
      const dateB = new Date(b.created_at || 0).getTime();
      return dateB - dateA;
    });
  }

  const createTask = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newTaskTitle.trim()) return
    const { data: { user } } = await supabase.auth.getUser()
    
    const tempId = Math.random().toString()
    setTasks(prev => [...prev, { 
      id: tempId, 
      title: newTaskTitle.trim(), 
      is_completed: false, 
      priority: newTaskPriority,
      created_at: new Date().toISOString()
    }])
    
    await supabase.from('tasks').insert({
      list_id: params.id,
      title: newTaskTitle.trim(),
      priority: newTaskPriority,
      created_by: user?.id
    })
    
    setNewTaskTitle('')
    setIsCreating(false)
  }

  const toggleTask = async (taskId: string, currentStatus: boolean) => {
    setTasks(prev => prev.map(t => t.id === taskId ? { ...t, is_completed: !currentStatus } : t))
    await supabase.from('tasks').update({ is_completed: !currentStatus }).eq('id', taskId)
  }

  const deleteTask = async (taskId: string) => {
    setTasks(prev => prev.filter(t => t.id !== taskId))
    await supabase.from('tasks').delete().eq('id', taskId)
  }

  const updateTask = async (id: string, e: React.FormEvent) => {
    e.preventDefault()
    if (!editTaskTitle.trim()) return
    setTasks(prev => prev.map(t => t.id === id ? { ...t, title: editTaskTitle.trim(), priority: editTaskPriority } : t))
    await supabase.from('tasks').update({ title: editTaskTitle.trim(), priority: editTaskPriority }).eq('id', id)
    setEditingTaskId(null)
  }

  const handleShare = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!shareEmail.trim()) return
    setShareLoading(true)

    const { error } = await supabase.rpc('invite_user_by_email', {
      p_list_id: params.id,
      p_email: shareEmail.trim(),
      p_role: 'editor'
    })

    if (error) {
      alert(error.message)
    } else {
      setIsShared(true)
      setIsSharing(false)
      setShareEmail('')
      alert('User invited successfully!')
    }
    setShareLoading(false)
  }

  const sortedTasks = sortTasks(tasks)

  return (
    <div className="animate-in fade-in duration-500 max-w-4xl mx-auto px-4 sm:px-0">
      {/* Share Modal */}
      {isSharing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-[#18181B] border border-white/10 p-6 md:p-8 rounded-2xl w-full max-w-md shadow-2xl">
            <h2 className="text-2xl font-bold mb-2">Share Project</h2>
            <p className="text-white/50 mb-6 text-sm md:text-base">Invite team members to collaborate in real-time.</p>
            <form onSubmit={handleShare}>
              <input
                type="email"
                required
                value={shareEmail}
                onChange={(e) => setShareEmail(e.target.value)}
                placeholder="colleague@example.com"
                className="w-full bg-[#1C1C1F] text-white px-5 py-4 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-white/5 mb-4"
              />
              <div className="flex justify-end gap-3">
                <button type="button" onClick={() => setIsSharing(false)} className="px-5 py-3 text-white/50 hover:text-white font-medium">Cancel</button>
                <button type="submit" disabled={shareLoading} className="px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-bold">
                  {shareLoading ? 'Inviting...' : 'Invite'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8 md:mb-12 mt-4 md:mt-0">
        <div className="flex items-center gap-3 sm:gap-4 flex-1">
          <button onClick={() => router.push('/dashboard')} className="p-2 sm:p-3 bg-[#18181B] hover:bg-white/10 rounded-xl transition border border-white/5 shrink-0">
            <ArrowLeft size={20} />
          </button>
          <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
            <h1 className="text-2xl sm:text-3xl md:text-4xl font-black tracking-tight">{listName}</h1>
            {isShared && <div className="bg-purple-500/20 text-purple-400 p-1.5 sm:p-2 rounded-lg" title="Shared Project"><Users size={16} className="sm:w-[18px] sm:h-[18px]" /></div>}
          </div>
        </div>

        <button 
          onClick={() => setIsSharing(true)}
          className="flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 text-white px-4 sm:px-5 py-3 rounded-xl font-bold transition w-full sm:w-auto"
        >
          <Share2 size={18} /> Share
        </button>
      </div>

      <div className="space-y-3 mb-8">
        {loading ? (
           <div className="flex justify-center p-12"><div className="w-8 h-8 rounded-full border-2 border-white/20 border-t-white animate-spin"></div></div>
        ) : sortedTasks.length === 0 ? (
          <div className="text-center p-8 sm:p-16 border border-white/5 border-dashed rounded-3xl bg-white/[0.01]">
            <p className="text-white/40 mb-6 font-medium text-sm sm:text-base">No tasks found. Begin planning.</p>
            <button onClick={() => setIsCreating(true)} className="px-6 py-3 bg-white text-black rounded-xl font-bold hover:bg-neutral-200 transition text-sm sm:text-base">Add Task</button>
          </div>
        ) : (
          <div className="grid gap-2">
          {sortedTasks.map(task => (
            <div 
              key={task.id} 
              className={`group flex flex-col sm:flex-row sm:items-center justify-between p-3 sm:p-4 rounded-xl border border-white/5 transition-all gap-3 ${
                task.is_completed ? 'bg-white/5' : 'bg-[#18181B] hover:bg-[#1C1C1F]'
              }`}
            >
              {editingTaskId === task.id ? (
                <form 
                  onSubmit={(e) => updateTask(task.id, e)}
                  className="flex flex-col sm:flex-row flex-1 items-stretch sm:items-center gap-3 w-full"
                >
                  <input 
                    autoFocus
                    type="text"
                    value={editTaskTitle}
                    onChange={(e) => setEditTaskTitle(e.target.value)}
                    className="flex-1 bg-[#27272A] text-white px-4 py-2 sm:py-3 rounded-lg outline-none focus:ring-2 focus:ring-purple-500"
                  />
                  <select 
                    value={editTaskPriority}
                    onChange={(e) => setEditTaskPriority(e.target.value)}
                    className="bg-[#27272A] text-white px-3 py-2 sm:py-3 rounded-lg outline-none"
                    title="Task Priority Edit"
                  >
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                  </select>
                  <div className="flex gap-2 justify-end mt-2 sm:mt-0">
                    <button type="button" onClick={() => setEditingTaskId(null)} className="px-4 py-2 text-white/50 hover:text-white bg-white/5 sm:bg-transparent rounded-lg sm:rounded-none">Cancel</button>
                    <button type="submit" className="px-6 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg font-bold">Save</button>
                  </div>
                </form>
              ) : (
                <div className="flex justify-between items-center w-full">
                  <div className="flex items-center gap-3 sm:gap-4 cursor-pointer flex-1" onClick={() => toggleTask(task.id, task.is_completed)}>
                    <button className={`p-1 shrink-0 rounded-full border transition-colors ${
                      task.is_completed 
                        ? 'bg-purple-500/20 border-purple-500/50 text-purple-400' 
                        : 'border-white/20 text-transparent hover:border-white/50'
                    }`}>
                      {task.is_completed ? <CheckCircle2 size={18} className="sm:w-[20px] sm:h-[20px]" /> : <Circle size={18} className="sm:w-[20px] sm:h-[20px]" />}
                    </button>
                    <span className={`text-base sm:text-lg font-medium transition-all break-words line-clamp-2 ${task.is_completed ? 'text-white/30 line-through' : 'text-white'}`}>
                      {task.title}
                    </span>
                    
                    {!task.is_completed && task.priority && (
                      <span className={`text-[9px] sm:text-[10px] px-2 py-1 rounded border font-bold uppercase tracking-wider shrink-0 ${
                        task.priority === 'high' ? 'bg-red-500/10 text-red-500 border-red-500/20' :
                        task.priority === 'medium' ? 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20' :
                        'bg-blue-500/10 text-blue-400 border-blue-500/20'
                      }`}>
                        {task.priority}
                      </span>
                    )}
                  </div>
                  <div className="flex gap-1 opacity-100 sm:opacity-0 group-hover:opacity-100 transition-opacity ml-2 shrink-0">
                    <button 
                      onClick={() => {
                        setEditingTaskId(task.id);
                        setEditTaskTitle(task.title);
                        setEditTaskPriority(task.priority || 'medium');
                      }}
                      className="p-1.5 sm:p-2 text-white/40 hover:text-white hover:bg-white/10 rounded-lg transition"
                      title="Edit Task"
                    >
                      <Edit2 size={16} className="sm:w-[18px] sm:h-[18px]" />
                    </button>
                    <button 
                      onClick={() => deleteTask(task.id)}
                      className="p-1.5 sm:p-2 text-white/40 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition"
                      title="Delete Task"
                    >
                      <Trash2 size={16} className="sm:w-[18px] sm:h-[18px]" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
        )}
      </div>

      {isCreating ? (
        <form onSubmit={createTask} className="flex flex-col sm:flex-row gap-3">
          <input
            type="text"
            autoFocus
            value={newTaskTitle}
            onChange={(e) => setNewTaskTitle(e.target.value)}
            placeholder="What needs to be done?"
            className="flex-1 bg-[#1C1C1F] text-white px-4 sm:px-5 py-3 sm:py-4 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-white/5 text-sm sm:text-base"
          />
          <select 
            title="Task Priority"
            value={newTaskPriority}
            onChange={(e) => setNewTaskPriority(e.target.value)}
            className="bg-[#1C1C1F] text-white px-4 py-3 sm:py-4 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-white/5 cursor-pointer text-sm sm:text-base"
          >
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
          <div className="flex gap-3 w-full sm:w-auto">
            <button type="submit" className="flex-1 sm:flex-none px-6 sm:px-8 py-3 sm:py-0 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-xl shadow-lg transition text-sm sm:text-base">Add</button>
            <button type="button" onClick={() => setIsCreating(false)} className="flex-1 sm:flex-none px-4 sm:px-6 py-3 sm:py-0 text-white/50 hover:text-white bg-white/5 sm:bg-transparent font-medium rounded-xl text-sm sm:text-base">Cancel</button>
          </div>
        </form>
      ) : tasks.length > 0 && (
        <button 
          onClick={() => setIsCreating(true)}
          className="flex items-center justify-center sm:justify-start w-full sm:w-auto gap-2 text-purple-400 hover:text-purple-300 font-bold px-4 py-3 bg-purple-500/10 hover:bg-purple-500/20 rounded-xl transition text-sm sm:text-base"
        >
          <Plus size={18} className="sm:w-[20px] sm:h-[20px]" /> Add new task
        </button>
      )}
    </div>
  )
}

