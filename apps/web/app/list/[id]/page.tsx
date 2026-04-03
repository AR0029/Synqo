'use client'

import { useState, useEffect } from 'react'
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
  
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    fetchData()
    const channel = supabase.channel(`tasks-${params.id}`).on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'tasks', filter: `list_id=eq.${params.id}` },
      () => fetchData()
    ).subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [params.id])

  const fetchData = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return router.push('/login')

    const { data: listData } = await supabase.from('lists').select('title, is_shared').eq('id', params.id).single()
    if (listData) {
      setListName(listData.title)
      setIsShared(listData.is_shared)
    }

    const { data: taskData } = await supabase.from('tasks').select('*').eq('list_id', params.id).order('created_at', { ascending: true })
    if (taskData) setTasks(taskData)

    setLoading(false)
  }

  const createTask = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newTaskTitle.trim()) return
    const { data: { user } } = await supabase.auth.getUser()
    
    const tempId = Math.random().toString()
    setTasks(prev => [...prev, { id: tempId, title: newTaskTitle.trim(), is_completed: false, priority: newTaskPriority }])
    
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

  return (
    <div className="animate-in fade-in duration-500 max-w-4xl mx-auto">
      {/* Share Modal */}
      {isSharing && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-[#18181B] border border-white/10 p-8 rounded-2xl w-full max-w-md shadow-2xl">
            <h2 className="text-2xl font-bold mb-2">Share Project</h2>
            <p className="text-white/50 mb-6">Invite team members to collaborate in real-time.</p>
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

      <div className="flex flex-col md:flex-row md:items-center gap-4 mb-12">
        <div className="flex items-center gap-4 flex-1">
          <button onClick={() => router.push('/dashboard')} className="p-3 bg-[#18181B] hover:bg-white/10 rounded-xl transition border border-white/5">
            <ArrowLeft size={20} />
          </button>
          <div className="flex items-center gap-3">
            <h1 className="text-4xl font-black tracking-tight">{listName}</h1>
            {isShared && <div className="bg-purple-500/20 text-purple-400 p-2 rounded-lg" title="Shared Project"><Users size={18} /></div>}
          </div>
        </div>

        <button 
          onClick={() => setIsSharing(true)}
          className="flex items-center justify-center gap-2 bg-white/5 hover:bg-white/10 border border-white/10 text-white px-5 py-3 rounded-xl font-bold transition"
        >
          <Share2 size={18} /> Share
        </button>
      </div>

      <div className="space-y-3 mb-8">
        {loading ? (
           <div className="flex justify-center p-12"><div className="w-8 h-8 rounded-full border-2 border-white/20 border-t-white animate-spin"></div></div>
        ) : tasks.length === 0 ? (
          <div className="text-center p-16 border border-white/5 border-dashed rounded-3xl bg-white/[0.01]">
            <p className="text-white/40 mb-6 font-medium">No tasks found. Begin planning.</p>
            <button onClick={() => setIsCreating(true)} className="px-6 py-3 bg-white text-black rounded-xl font-bold hover:bg-neutral-200 transition">Add Task</button>
          </div>
        ) : (
          <div className="grid gap-2">
          {tasks.map(task => (
            <div 
              key={task.id} 
              className={`group flex items-center justify-between p-4 rounded-xl border border-white/5 transition-all ${
                task.is_completed ? 'bg-white/5' : 'bg-[#18181B] hover:bg-[#1C1C1F]'
              }`}
            >
              {editingTaskId === task.id ? (
                <form 
                  onSubmit={(e) => updateTask(task.id, e)}
                  className="flex flex-1 items-center gap-3 w-full"
                >
                  <input 
                    autoFocus
                    type="text"
                    value={editTaskTitle}
                    onChange={(e) => setEditTaskTitle(e.target.value)}
                    className="flex-1 bg-[#27272A] text-white px-4 py-2 rounded-lg outline-none focus:ring-2 focus:ring-purple-500"
                  />
                  <select 
                    value={editTaskPriority}
                    onChange={(e) => setEditTaskPriority(e.target.value)}
                    className="bg-[#27272A] text-white px-3 py-2 rounded-lg outline-none"
                    title="Task Priority Edit"
                  >
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                  </select>
                  <button type="button" onClick={() => setEditingTaskId(null)} className="px-3 text-white/50 hover:text-white">Cancel</button>
                  <button type="submit" className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg font-bold">Save</button>
                </form>
              ) : (
                <>
                  <div className="flex items-center gap-4 cursor-pointer flex-1" onClick={() => toggleTask(task.id, task.is_completed)}>
                    <button className={`p-1 rounded-full border transition-colors ${
                      task.is_completed 
                        ? 'bg-purple-500/20 border-purple-500/50 text-purple-400' 
                        : 'border-white/20 text-transparent hover:border-white/50'
                    }`}>
                      {task.is_completed ? <CheckCircle2 size={20} /> : <Circle size={20} />}
                    </button>
                    <span className={`text-lg font-medium transition-all ${task.is_completed ? 'text-white/30 line-through' : 'text-white'}`}>
                      {task.title}
                    </span>
                    
                    {!task.is_completed && task.priority && (
                      <span className={`text-[10px] px-2 py-1 rounded border font-bold uppercase tracking-wider ${
                        task.priority === 'high' ? 'bg-red-500/10 text-red-500 border-red-500/20' :
                        task.priority === 'medium' ? 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20' :
                        'bg-blue-500/10 text-blue-400 border-blue-500/20'
                      }`}>
                        {task.priority}
                      </span>
                    )}
                  </div>
                  <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button 
                      onClick={() => {
                        setEditingTaskId(task.id);
                        setEditTaskTitle(task.title);
                        setEditTaskPriority(task.priority || 'medium');
                      }}
                      className="p-2 text-white/40 hover:text-white hover:bg-white/10 rounded-lg transition"
                      title="Edit Task"
                    >
                      <Edit2 size={18} />
                    </button>
                    <button 
                      onClick={() => deleteTask(task.id)}
                      className="p-2 text-white/40 hover:text-red-500 hover:bg-red-500/10 rounded-lg transition"
                      title="Delete Task"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                </>
              )}
            </div>
          ))}
        </div>
        )}
      </div>

      {isCreating ? (
        <form onSubmit={createTask} className="flex gap-3">
          <input
            type="text"
            autoFocus
            value={newTaskTitle}
            onChange={(e) => setNewTaskTitle(e.target.value)}
            placeholder="What needs to be done?"
            className="flex-1 bg-[#1C1C1F] text-white px-5 py-4 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-white/5"
          />
          <select 
            title="Task Priority"
            value={newTaskPriority}
            onChange={(e) => setNewTaskPriority(e.target.value)}
            className="bg-[#1C1C1F] text-white px-4 py-4 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 border border-white/5 cursor-pointer"
          >
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
          <button type="submit" className="px-8 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-xl shadow-lg transition">Add</button>
          <button type="button" onClick={() => setIsCreating(false)} className="px-6 text-white/50 hover:text-white font-medium rounded-xl">Cancel</button>
        </form>
      ) : tasks.length > 0 && (
        <button 
          onClick={() => setIsCreating(true)}
          className="flex items-center gap-2 text-purple-400 hover:text-purple-300 font-bold px-4 py-3 bg-purple-500/10 hover:bg-purple-500/20 rounded-xl transition"
        >
          <Plus size={20} /> Add new task
        </button>
      )}
    </div>
  )
}
