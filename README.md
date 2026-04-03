<div align="center">
  <img src="https://synqoo.vercel.app/favicon.ico" alt="Synqo Logo" width="80" height="80">
  <h1 align="center">Synqo</h1>
  <p align="center">
    <strong>The Ultimate Cross-Platform Collaborative Workspace</strong>
    <br />
    <a href="https://synqoo.vercel.app/"><strong>Explore the Web App »</strong></a>
    <br />
    <br />
    <a href="https://github.com/AR0029/Synqo/issues">Report Bug</a>
    ·
    <a href="https://github.com/AR0029/Synqo/issues">Request Feature</a>
  </p>
</div>

<br />

## 🌟 About The Project

**Synqo** is a premium, real-time task management and collaborative workspace engineered from the ground up for performance and aesthetic excellence. Designed with a striking dark glassmorphic UI, Synqo seamlessly bridging the gap between desktop web and mobile environments through its unified monorepo architecture. 

Whether you are managing solo priorities or collaborating on shared lists with team members, Synqo delivers millisecond-level data synchronization powered by Postgres Realtime.

### ✨ Key Features
- **Real-Time Collaboration**: Share lists instantly. When a collaborator adds, edits, or deletes a task, the interface updates live via Websockets without page reloads.
- **Cross-Platform Native**: Includes a responsive Next.js Web App and a fully compiled native Flutter Android Application, both sharing the same backend ecosystem.
- **Glassmorphic Aesthetic**: Designed with an ultra-premium frosted-glass dark mode, featuring ambient glows and fluid animations.
- **Priority Management**: Tag tasks with distinct visual importance levels (High, Medium, Low) to keep workspaces organized.
- **Secure Authentication**: Robust email/password authentication baked into both Web and Mobile seamlessly via Supabase Auth.

---

## 🛠️ Built With

This project operates as a modern monorepo, housing both the Web and Mobile ecosystems alongside the backend infrastructure.

### The Stack
* **Web**: [Next.js 14](https://nextjs.org/), [React](https://reactjs.org/), [Tailwind CSS](https://tailwindcss.com/), [Lucide Icons](https://lucide.dev/)
* **Mobile**: [Flutter](https://flutter.dev/), [Dart](https://dart.dev/), Riverpod
* **Backend Platform**: [Supabase](https://supabase.com/)
* **Database**: PostgreSQL with Row Level Security (RLS) policies.

---

## 🚀 Live Demo

- **Web Application**: Dive into the live experience at [synqoo.vercel.app](https://synqoo.vercel.app/)
- **Mobile Application**: The Android APK can be built directly from the `apps/mobile` directory.

---

## 💻 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

You need Node.js, Flutter SDK, and a Supabase Project.

### Installation

1. **Clone the repo**
   ```sh
   git clone https://github.com/AR0029/Synqo.git
   ```
2. **Setup Vercel/Next Web**
   ```sh
   cd apps/web
   npm install
   ```
3. **Configure Environment Variables required for Web & Mobile**
   Create a `.env.local` inside `apps/web`:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
   NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```
4. **Run the Web Development Server**
   ```sh
   npm run dev
   ```

5. **Run the Flutter Application**
   ```sh
   cd ../mobile
   flutter pub get
   flutter run
   ```

---

## 🔒 Database Architecture

Synqo utilizes advanced PostgreSQL features. Collaborative sharing works by linking users via a `list_members` junction table.

* **`users` (auth schema)**: Managed automatically by Supabase Auth.
* **`profiles` (public)**: Stores core user data dynamically linked on account creation.
* **`lists`**: Represents isolated workspaces. Both web and mobile subscribe to changes scoped to their accessible lists.
* **`list_members`**: Handles complex collaboration logic, determining who can view or edit nested task arrays. 
* **`tasks`**: The core operational data unit, deeply integrated with Priority enums.

*Extensive Row Level Security (RLS) guarantees that users can ONLY fetch data explicitly shared with them.*

---

## 👨‍💻 Developed By

**Aryan Chaudhary** 
Software Engineer | M.Tech CSE Scholar

*   **Portfolio**: [ar0029.vercel.app](https://ar0029.vercel.app/)
*   **LinkedIn**: [Aryan Chaudhary](https://www.linkedin.com/in/ar0029/)
*   **GitHub**: [@AR0029](https://github.com/AR0029)

<br/>
<p align="center">Made with passion by Aryan Chaudhary.</p>
