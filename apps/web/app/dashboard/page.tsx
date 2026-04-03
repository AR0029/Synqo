'use client'

import { useState, useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Layers, ChevronRight, Plus, Users, Edit2, Trash2 } from 'lucide-react'
import { useRouter } from 'next/navigation'

export default function Dashboard() {
  const [lists, setLists] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [isCreating, setIsCreating] = useState(false)
  const [newTitle, setNewTitle] = useState('')
  const [editingList, setEditingList] = useState<string | null>(null)
  const [editListTitle, setEditListTitle] = useState('')
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    fetchLists()
    const channel = supabase.channel('public:lists').on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'lists' },
      () => fetchLists()
    ).subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const fetchLists = async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      router.push('/login')
      return
    }

    const { data, error } = await supabase.from('lists').select('*').order('created_at', { ascending: false })
    if (data) setLists(data)
    setLoading(false)
  }

  const createList = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newTitle.trim()) return
    const { data: { user } } = await supabase.auth.getUser()
    await supabase.from('lists').insert({ title: newTitle.trim(), owner_id: user?.id })
    setNewTitle('')
    setIsCreating(false)
    fetchLists()
  }

  const updateList = async (id: string, e: React.FormEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (!editListTitle.trim()) return
    await supabase.from('lists').update({ title: editListTitle.trim() }).eq('id', id)
    setEditingList(null)
    fetchLists()
  }

  const deleteList = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation()
    const confirmDelete = window.confirm("Are you sure you want to delete this project? This will erase all tasks and share settings.")
    if (confirmDelete) {
      await supabase.from('lists').delete().eq('id', id)
      fetchLists()
    }
  }

  return (
    <div className="animate-in fade-in duration-500">
      <div className="flex items-center justify-between mb-12">
        <h1 className="text-4xl font-black tracking-tight">Projects</h1>
        <button
          onClick={() => setIsCreating(true)}
          className="flex items-center gap-2 bg-white text-black px-5 py-3 rounded-xl font-bold hover:bg-neutral-200 transition shadow-[0_0_20px_rgba(255,255,255,0.1)]"
        >
          <Plus size={20} /> New Project
        </button>
      </div>

      {isCreating && (
        <form onSubmit={createList} className="mb-8 p-6 bg-[#18181B] border border-white/5 rounded-2xl">
          <input
            type="text"
            autoFocus
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            placeholder="e.g. Website Redesign"
            className="w-full bg-[#1C1C1F] text-white px-5 py-4 rounded-xl outline-none focus:ring-2 focus:ring-purple-500 text-lg border-none"
          />
          <div className="flex justify-end gap-3 mt-4">
            <button type="button" onClick={() => setIsCreating(false)} className="px-5 py-3 text-white/50 hover:text-white font-medium">Cancel</button>
            <button type="submit" className="px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-bold">Create</button>
          </div>
        </form>
      )}

      {loading ? (
        <div className="flex justify-center p-20"><div className="w-8 h-8 rounded-full border-2 border-white/20 border-t-white animate-spin"></div></div>
      ) : lists.length === 0 ? (
        <div className="text-center p-20 border border-white/5 border-dashed rounded-3xl bg-white/[0.01]">
          <Layers size={48} className="mx-auto mb-6 text-white/20" />
          <h2 className="text-xl font-bold mb-2">No projects yet</h2>
          <p className="text-white/40 mb-8">Create your first project to get started.</p>
          <button onClick={() => setIsCreating(true)} className="px-6 py-3 bg-white text-black rounded-xl font-bold hover:bg-white/90 transition">Create Project</button>
        </div>
      ) : (
        <div className="grid gap-4">
          {lists.map(list => (
            <div
              key={list.id}
              onClick={() => { if (editingList !== list.id) router.push(`/list/${list.id}`) }}
              className="group cursor-pointer p-6 bg-[#18181B] hover:bg-[#1C1C1F] border border-white/5 border-b-black/50 hover:border-white/10 rounded-2xl transition-all shadow-lg flex items-center justify-between"
            >
              <div className="flex items-center gap-5 flex-1">
                <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center shadow-inner shrink-0">
                  <Layers className="text-white drop-shadow-md" size={24} />
                </div>
                {editingList === list.id ? (
                  <form 
                    className="flex-1 mr-4"
                    onSubmit={(e) => updateList(list.id, e)}
                    onClick={(e) => e.stopPropagation()}
                  >
                    <input 
                      autoFocus
                      type="text"
                      value={editListTitle}
                      onChange={(e) => setEditListTitle(e.target.value)}
                      className="w-full bg-[#27272A] text-white px-4 py-2 rounded-lg outline-none focus:ring-2 focus:ring-purple-500"
                    />
                  </form>
                ) : (
                  <div className="flex items-center gap-3">
                    <h3 className="text-xl font-bold tracking-tight">{list.title}</h3>
                    {list.is_shared && (
                      <div className="bg-purple-500/20 text-purple-400 p-1.5 rounded-md" title="Shared Project">
                        <Users size={14} />
                      </div>
                    )}
                  </div>
                )}
              </div>
              <div className="flex items-center gap-2">
                {editingList === list.id ? (
                  <div className="flex gap-2">
                    <button 
                      onClick={(e) => { e.stopPropagation(); setEditingList(null); }}
                      className="p-2 bg-white/10 hover:bg-white/20 rounded-lg text-white/50 hover:text-white transition"
                    >
                      Cancel
                    </button>
                    <button 
                      onClick={(e) => updateList(list.id, e as any)}
                      className="p-2 bg-purple-600 hover:bg-purple-700 rounded-lg font-bold text-white transition"
                    >
                      Save
                    </button>
                  </div>
                ) : (
                  <>
                    <button 
                      onClick={(e) => {
                        e.stopPropagation();
                        setEditingList(list.id);
                        setEditListTitle(list.title);
                      }}
                      className="opacity-0 group-hover:opacity-100 p-2 text-white/40 hover:text-white bg-white/5 hover:bg-white/10 rounded-lg transition"
                      title="Edit Project"
                    >
                      <Edit2 size={18} />
                    </button>
                    <button 
                      onClick={(e) => deleteList(list.id, e)}
                      className="opacity-0 group-hover:opacity-100 p-2 text-white/40 hover:text-red-500 bg-white/5 hover:bg-red-500/20 rounded-lg transition mr-2"
                      title="Delete Project"
                    >
                      <Trash2 size={18} />
                    </button>
                    <ChevronRight className="text-white/20 group-hover:text-white/50 transition-colors" />
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
