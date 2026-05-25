import React, { useState } from "react";
import { motion } from "framer-motion";
import {
  Bell,
  CheckCircle2,
  ChevronRight,
  Clock3,
  Copy,
  Home,
  Inbox,
  Lock,
  Mail,
  MessageSquareText,
  RefreshCcw,
  RotateCcw,
  Settings,
  ShieldCheck,
  Sparkles,
  TimerReset,
  WalletCards,
  XCircle,
  ListChecks,
  FileText,
  Send,
  Search,
  CalendarClock,
  AlertTriangle,
  UserRound,
} from "lucide-react";

const screenNames = [
  "Auth",
  "Onboarding",
  "Starter Intro",
  "Home",
  "Templates",
  "New Task",
  "Loading",
  "Clarification",
  "Task Result",
  "My Tasks Empty",
  "My Tasks",
  "Task Detail",
  "Draft Reply",
  "Reminder",
  "Limited",
  "Subscription",
  "Access",
  "Settings",
  "Edge States",
];

const styles = {
  ink: "text-slate-950",
  muted: "text-slate-500",
  accent: "#176B5B",
  bg: "#EEF3F0",
};

function Pill({ children, tone = "neutral", icon: Icon }) {
  const tones = {
    neutral: "bg-white/48 text-slate-700 border-white/75",
    good: "bg-emerald-100/72 text-emerald-800 border-emerald-200/80",
    warn: "bg-orange-100/72 text-orange-800 border-orange-200/80",
    danger: "bg-rose-100/72 text-rose-800 border-rose-200/80",
    info: "bg-sky-100/72 text-sky-800 border-sky-200/80",
  };
  return (
    <span className={`inline-flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-full border px-3 py-1 text-[12px] font-semibold backdrop-blur-xl ${tones[tone]}`}>
      {Icon ? <Icon size={13} /> : null}
      {children}
    </span>
  );
}

function Button({ children, variant = "primary", icon: Icon, className = "" }) {
  const variants = {
    primary: "bg-[#176B5B] text-white shadow-[0_16px_34px_rgba(23,107,91,0.28)]",
    secondary: "border border-white/75 bg-white/56 text-[#176B5B] shadow-sm backdrop-blur-2xl",
    soft: "bg-emerald-100/80 text-emerald-900",
    danger: "bg-rose-100/80 text-rose-900",
  };
  return (
    <button className={`flex min-h-[48px] items-center justify-center gap-2 rounded-2xl px-4 py-3 text-[14px] font-bold active:scale-[0.99] ${variants[variant]} ${className}`}>
      {Icon ? <Icon size={17} /> : null}
      {children}
    </button>
  );
}

function Card({ children, className = "" }) {
  return (
    <div className={`rounded-[30px] border border-white/72 bg-white/58 p-5 shadow-[0_18px_50px_rgba(37,50,44,0.10)] backdrop-blur-2xl ${className}`}>
      {children}
    </div>
  );
}

function Field({ label, value, type = "input" }) {
  return (
    <div>
      <div className="mb-2 text-[13px] font-black text-slate-900">{label}</div>
      <div className={`${type === "textarea" ? "min-h-[150px] items-start p-4" : "h-12 items-center px-4"} flex rounded-3xl border border-white/80 bg-white/44 text-[15px] leading-6 text-slate-600 backdrop-blur-xl`}>
        {value}
      </div>
    </div>
  );
}

function IllustrationCard({ title, subtitle, type = "steps" }) {
  return (
    <Card className="relative overflow-hidden p-4">
      <div className="absolute -right-10 -top-10 h-28 w-28 rounded-full bg-emerald-200/45 blur-2xl" />
      <div className="absolute -bottom-12 left-10 h-24 w-24 rounded-full bg-orange-200/45 blur-2xl" />
      <div className="relative flex items-center justify-between gap-4">
        <div>
          <div className="text-[13px] font-black text-slate-950">{title}</div>
          <div className="mt-1 max-w-[170px] text-[11px] leading-4 text-slate-500">{subtitle}</div>
        </div>
        <div className="relative h-20 w-28 shrink-0">
          {type === "message" ? (
            <>
              <div className="absolute left-2 top-3 h-14 w-20 rounded-[22px] border border-white/80 bg-white/64 shadow-sm backdrop-blur-xl" />
              <div className="absolute right-1 top-0 h-14 w-14 rounded-full bg-orange-100/80 shadow-sm" />
              <div className="absolute bottom-2 right-8 flex h-10 w-10 items-center justify-center rounded-2xl bg-[#176B5B] text-white shadow-[0_14px_26px_rgba(23,107,91,0.26)]">
                <MessageSquareText size={18} />
              </div>
            </>
          ) : (
            <>
              <div className="absolute left-1 top-2 h-12 w-12 rotate-[-10deg] rounded-2xl border border-white/80 bg-white/64 shadow-sm backdrop-blur-xl" />
              <div className="absolute left-9 top-6 h-12 w-12 rotate-[8deg] rounded-2xl border border-white/80 bg-emerald-100/70 shadow-sm backdrop-blur-xl" />
              <div className="absolute right-1 top-1 flex h-12 w-12 items-center justify-center rounded-full bg-[#176B5B] text-white shadow-[0_14px_26px_rgba(23,107,91,0.26)]">
                <CheckCircle2 size={22} />
              </div>
            </>
          )}
        </div>
      </div>
    </Card>
  );
}

function OrbIcon({ icon: Icon = Sparkles, tone = "green" }) {
  const tones = {
    green: "bg-[#176B5B] text-white shadow-[0_14px_30px_rgba(23,107,91,0.24)]",
    orange: "bg-orange-100 text-orange-800",
    white: "bg-white/60 text-slate-700 border border-white/70 backdrop-blur-xl",
  };
  return <div className={`flex h-12 w-12 items-center justify-center rounded-2xl ${tones[tone]}`}><Icon size={22} /></div>;
}

function TabBar({ active = "Home" }) {
  const nav = [[Home, "Home"], [Inbox, "Tasks"], [MessageSquareText, "Templates"], [Settings, "Settings"]];
  return (
    <div className="relative mx-5 mb-5 rounded-[34px] border border-white/75 bg-white/54 p-2 shadow-[0_22px_56px_rgba(37,50,44,0.16)] backdrop-blur-3xl">
      <div className="grid grid-cols-5 items-center">
        {nav.slice(0, 2).map(([Icon, label]) => <NavItem key={label} Icon={Icon} label={label} active={active === label} />)}
        <div className="relative flex justify-center">
          <div className="absolute -top-8 flex h-16 w-16 items-center justify-center rounded-full border-[6px] border-[#F7F8F1] bg-[#176B5B] text-white shadow-[0_20px_42px_rgba(23,107,91,0.34)]">
            <span className="-mt-1 text-[36px] font-light">+</span>
          </div>
          <div className="pt-9 text-[11px] font-black text-[#176B5B]">Task</div>
        </div>
        {nav.slice(2).map(([Icon, label]) => <NavItem key={label} Icon={Icon} label={label} active={active === label} />)}
      </div>
    </div>
  );
}

function NavItem({ Icon, label, active }) {
  return (
    <div className={`flex flex-col items-center gap-1 rounded-2xl py-2 text-[11px] ${active ? "text-[#176B5B]" : "text-slate-400"}`}>
      <Icon size={18} />
      {label}
    </div>
  );
}

function Phone({ title, subtitle, children, footer = true, activeTab = "Home" }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28 }}
      className="relative h-[844px] w-[390px] overflow-hidden rounded-[46px] border border-white/80 bg-[#F7F8F1] shadow-[0_30px_100px_rgba(37,50,44,0.24)]"
    >
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_14%_6%,rgba(23,107,91,0.22),transparent_32%),radial-gradient(circle_at_92%_18%,rgba(232,148,93,0.20),transparent_34%),linear-gradient(180deg,rgba(255,255,255,0.84),rgba(255,255,255,0.22))]" />
      <div className="absolute left-1/2 top-3 z-20 h-6 w-28 -translate-x-1/2 rounded-full bg-slate-950" />
      <div className="relative z-10 flex h-full flex-col">
        <div className="px-6 pb-3 pt-12">
          <div className="mb-4 flex items-center justify-between">
            <div className="min-w-0 pr-3">
              <div className="text-[24px] font-black tracking-[-0.04em] text-slate-950">{title}</div>
              {subtitle ? <div className="mt-1 text-[13px] leading-5 text-slate-500">{subtitle}</div> : null}
            </div>
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl border border-white/75 bg-white/54 text-slate-600 shadow-sm backdrop-blur-2xl">
              <Bell size={18} />
            </div>
          </div>
        </div>
        <div className="flex-1 overflow-hidden px-6 pb-5">{children}</div>
        {footer ? <TabBar active={activeTab} /> : null}
      </div>
    </motion.div>
  );
}

function AuthScreen() {
  return (
    <Phone title="Welcome to OneDone" subtitle="Sign up or log in to continue" footer={false}>
      <div className="flex h-full flex-col justify-between pb-5">
        <div className="space-y-4">
          <IllustrationCard title="Life admin, less messy" subtitle="Turn everyday admin tasks into clear steps." />
          <Card className="space-y-4">
            <Field label="Email" value="you@example.com" />
            <Field label="Password" value="••••••••" />
          </Card>
          <div className="grid gap-3">
            <Button icon={UserRound}>Sign up</Button>
            <Button variant="secondary" icon={Mail}>Log in</Button>
          </div>
        </div>
        <p className="text-center text-[12px] leading-5 text-slate-500">A guided self-service assistant. No autonomous actions.</p>
      </div>
    </Phone>
  );
}

function OnboardingScreen() {
  return (
    <Phone title="Let’s keep it simple" subtitle="OneDone helps you finish one admin task at a time." footer={false}>
      <div className="flex h-full flex-col justify-between pb-5">
        <div className="space-y-4">
          <Card><OrbIcon icon={ListChecks} /><h2 className="mt-5 text-[28px] font-black leading-[1] tracking-[-0.06em] text-slate-950">No more open loops.</h2><p className="mt-3 text-[15px] leading-6 text-slate-600">Get the next step, a checklist, a draft reply, and a reminder when needed.</p></Card>
          {["Subscriptions and refunds", "Bills and policies", "Replies and complaints", "Follow-ups and reminders"].map((item) => <div key={item} className="flex items-center gap-3 rounded-3xl border border-white/70 bg-white/54 p-4 text-[14px] font-bold text-slate-800 backdrop-blur-2xl"><CheckCircle2 size={18} className="text-[#176B5B]" />{item}</div>)}
        </div>
        <div className="flex justify-center"><Button className="w-full max-w-[260px]">Start with 3 free days</Button></div>
      </div>
    </Phone>
  );
}

function StarterIntroScreen() {
  return (
    <Phone title="Your first 3 days are open" subtitle="Try the full task loop before the App Store trial." footer={false}>
      <div className="flex h-full flex-col justify-between pb-5">
        <div className="space-y-4">
          <IllustrationCard title="Starter Access" subtitle="Create tasks, generate replies, set reminders." />
          <Card>{["10 AI actions per day", "Task breakdowns", "Draft replies", "Follow-up reminders"].map((item) => <div key={item} className="flex items-center gap-3 border-t border-slate-200/60 py-3 first:border-t-0 first:pt-0 text-[14px] text-slate-700"><CheckCircle2 size={17} className="text-[#176B5B]" />{item}</div>)}</Card>
        </div>
        <div className="flex justify-center"><Button className="w-full max-w-[260px]">Continue to Home</Button></div>
      </div>
    </Phone>
  );
}

function HomeScreen() {
  return (
    <Phone title="Good morning" subtitle="Pick one admin task and move it forward." activeTab="Home">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <Pill tone="good" icon={ShieldCheck}>Starter: 3 days left</Pill>
          <span className="text-[12px] text-slate-500">Tap + to add</span>
        </div>
        <IllustrationCard title="From messy to manageable" subtitle="OneDone turns vague admin stress into a clear next step." />
        <Card>
          <div className="mb-4 flex items-center justify-between">
            <div><h2 className="text-[20px] font-black tracking-[-0.04em] text-slate-950">What OneDone can help with</h2><p className="mt-1 text-[13px] text-slate-500">Choose a shortcut or tap + to start fresh.</p></div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {[["Cancel subscription", WalletCards], ["Request refund", RotateCcw], ["Understand bill", FileText], ["Reply politely", MessageSquareText]].map(([label, Icon]) => (
              <div key={label} className="rounded-3xl border border-white/70 bg-white/42 p-4 backdrop-blur-xl">
                <Icon className="mb-3 text-[#176B5B]" size={20} />
                <div className="text-[13px] font-black leading-5 text-slate-900">{label}</div>
              </div>
            ))}
          </div>
        </Card>
        <Card className="p-4"><div className="flex items-center justify-between"><div><div className="text-[14px] font-black text-slate-950">Next up</div><div className="mt-1 text-[12px] text-slate-500">Refund subscription charge</div></div><Pill tone="warn">Waiting</Pill></div></Card>
      </div>
    </Phone>
  );
}

function TemplatesScreen() {
  return (
    <Phone title="Templates" subtitle="Start with a familiar situation." activeTab="Templates">
      <div className="space-y-3">
        {[["Cancel a subscription", WalletCards, "Find where it started and what to do next."], ["Return an item", RotateCcw, "Prepare evidence and a clear message."], ["Understand a bill", FileText, "Break down fees and next questions."], ["Write a complaint", MessageSquareText, "Firm, polite, and useful."], ["Request a refund", RefreshCcw, "Ask clearly without overexplaining."], ["Follow up", TimerReset, "A gentle reminder when no one replied."]].map(([title, Icon, subtitle]) => (
          <Card key={title} className="p-4"><div className="flex items-center gap-3"><OrbIcon icon={Icon} tone="white" /><div className="min-w-0 flex-1"><div className="text-[15px] font-black text-slate-950">{title}</div><div className="mt-1 text-[12px] leading-4 text-slate-500">{subtitle}</div></div><ChevronRight size={18} className="text-slate-400" /></div></Card>
        ))}
      </div>
    </Phone>
  );
}

function NewTaskScreen() {
  return (
    <Phone title="New task" subtitle="Opened from the elevated + button." activeTab="New">
      <div className="space-y-4">
        <IllustrationCard title="Text-first MVP" subtitle="Paste the message, bill, or policy text. Uploads stay coming soon." type="message" />
        <Card className="space-y-4">
          <Field label="Task description" type="textarea" value="I was charged for a subscription I forgot to cancel. I want to ask if they can refund the latest charge." />
          <div className="flex gap-2"><Pill>Optional deadline</Pill><Pill>Auto category</Pill></div>
        </Card>
        <div className="flex justify-center"><Button icon={Sparkles} className="w-full max-w-[260px]">Analyze task</Button></div>
      </div>
    </Phone>
  );
}

function LoadingScreen() {
  return (
    <Phone title="Analyzing" subtitle="OneDone is turning this into a clear path." activeTab="New">
      <div className="flex h-full flex-col items-center justify-center pb-24 text-center">
        <div className="relative mb-6 h-28 w-28"><div className="absolute inset-0 rounded-full bg-emerald-200/60 blur-2xl" /><div className="relative flex h-28 w-28 items-center justify-center rounded-[36px] border border-white/80 bg-white/58 backdrop-blur-3xl"><Sparkles size={34} className="text-[#176B5B]" /></div></div>
        <h2 className="text-[24px] font-black tracking-[-0.05em] text-slate-950">Finding the next step</h2>
        <p className="mt-3 max-w-[260px] text-[14px] leading-6 text-slate-500">If something important is missing, OneDone will ask one clear question.</p>
      </div>
    </Phone>
  );
}

function ClarificationScreen() {
  return (
    <Phone title="One detail" subtitle="To give the right steps, I need one missing piece." activeTab="New">
      <div className="space-y-4">
        <Card><Pill tone="warn" icon={Clock3}>Needs clarification</Pill><h2 className="mt-4 text-[22px] font-black tracking-[-0.04em] text-slate-950">Where was this subscription started?</h2><p className="mt-2 text-[14px] leading-6 text-slate-500">This changes the cancellation and refund path.</p></Card>
        {["Apple App Store", "Company website", "Google Play", "I’m not sure"].map((item) => <div key={item} className="flex items-center justify-between rounded-3xl border border-white/70 bg-white/56 p-4 shadow-sm backdrop-blur-2xl"><span className="text-[15px] font-bold text-slate-900">{item}</span><ChevronRight size={18} className="text-slate-400" /></div>)}
        <div className="flex flex-col items-center gap-3"><Button className="w-full max-w-[260px]">Continue</Button><Button variant="secondary" className="w-full max-w-[260px]">Skip for now</Button></div>
      </div>
    </Phone>
  );
}

function TaskResultScreen() {
  return (
    <Phone title="Here’s the next step" subtitle="Refund request · Generated just now" activeTab="New">
      <div className="space-y-4">
        <IllustrationCard title="Useful path found" subtitle="Start with a polite goodwill refund request." />
        <Card><h2 className="text-[22px] font-black tracking-[-0.04em] text-slate-950">Ask for a goodwill refund first.</h2><p className="mt-3 text-[15px] leading-6 text-slate-600">Mention the date, amount, and that you cancelled as soon as you noticed.</p></Card>
        <Checklist items={["Find the charge date and amount", "Cancel the subscription first", "Send refund request", "Set a follow-up reminder"]} />
        <div className="grid grid-cols-2 gap-3"><Button icon={MessageSquareText}>Draft reply</Button><Button variant="secondary" icon={TimerReset}>Reminder</Button></div>
      </div>
    </Phone>
  );
}

function Checklist({ items }) {
  const [checked, setChecked] = useState(() => items.map((_, index) => index === 0));
  return (
    <Card>
      <div className="mb-3 flex items-center justify-between">
        <div className="text-[15px] font-black text-slate-900">Checklist</div>
        <Pill tone="good">Tap to check</Pill>
      </div>
      {items.map((item, index) => (
        <button
          key={item}
          onClick={() => setChecked((current) => current.map((value, i) => (i === index ? !value : value)))}
          className="flex w-full items-start gap-3 border-t border-slate-200/60 py-3 text-left first:border-t-0 first:pt-0"
        >
          <div className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full transition ${checked[index] ? "bg-[#176B5B] text-white shadow-sm" : "border border-slate-300/80 bg-white/50"}`}>
            {checked[index] ? <CheckCircle2 size={15} /> : null}
          </div>
          <span className={`text-[14px] leading-5 ${checked[index] ? "text-slate-400 line-through decoration-slate-400/70" : "text-slate-600"}`}>{item}</span>
        </button>
      ))}
    </Card>
  );
}

function MyTasksEmptyScreen() {
  return (
    <Phone title="My Tasks" subtitle="Tasks will appear here once you start." activeTab="Tasks">
      <div className="flex h-full flex-col justify-center pb-24 text-center"><IllustrationCard title="Nothing here yet" subtitle="Tap the + button to turn one messy thing into a clear plan." /><div className="mt-4 flex justify-center"><Button icon={Sparkles} className="w-full max-w-[260px]">Create first task</Button></div></div>
    </Phone>
  );
}

function MyTasksScreen() {
  const tasks = [["Refund subscription charge", "Waiting", "Follow up tomorrow", "warn"], ["Return damaged package", "In progress", "Take photos first", "info"], ["Understand internet bill", "Clarify", "Paste bill text", "danger"]];
  return (
    <Phone title="My Tasks" subtitle="A follow-through hub, not a generic to-do list." activeTab="Tasks">
      <div className="space-y-4"><div className="flex gap-2 overflow-hidden"><Pill tone="good">All</Pill><Pill>Due soon</Pill><Pill>Waiting</Pill></div>{tasks.map(([title, status, next, tone]) => <TaskCard key={title} title={title} status={status} next={next} tone={tone} />)}</div>
    </Phone>
  );
}

function TaskCard({ title, status, next, tone }) {
  return (
    <Card className="p-4">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <div className="truncate text-[16px] font-black tracking-[-0.02em] text-slate-950">{title}</div>
          <p className="mt-1 truncate text-[13px] text-slate-500">{next}</p>
        </div>
        <span className={`shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-black uppercase tracking-[0.06em] ${tone === "warn" ? "border-orange-200/80 bg-orange-100/72 text-orange-800" : tone === "danger" ? "border-rose-200/80 bg-rose-100/72 text-rose-800" : "border-sky-200/80 bg-sky-100/72 text-sky-800"}`}>{status}</span>
      </div>
      <div className="mt-4 flex items-center justify-between border-t border-slate-200/60 pt-3 text-[12px] text-slate-500">
        <span>Last updated 18 min ago</span>
        <ChevronRight size={17} />
      </div>
    </Card>
  );
}

function TaskDetailScreen() {
  return (
    <Phone title="Task Detail" subtitle="Refund subscription charge" activeTab="Tasks">
      <div className="space-y-4"><div className="flex gap-2"><Pill tone="warn">Waiting for reply</Pill><Pill>Reminder tomorrow</Pill></div><Card><div className="text-[12px] font-black uppercase tracking-[0.14em] text-slate-400">Current next step</div><h2 className="mt-2 text-[20px] font-black tracking-[-0.04em] text-slate-950">Wait for support response, then follow up if needed.</h2></Card><IllustrationCard title="Progress saved" subtitle="Reply sent, reminder scheduled, next step ready." /><Timeline /></div>
    </Phone>
  );
}

function Timeline() {
  return <Card><div className="mb-3 text-[15px] font-black text-slate-900">Timeline</div>{[["Reply copied", "Today, 10:24"], ["Message marked sent", "Today, 10:25"], ["Reminder created", "Tomorrow, 09:00"]].map(([event, time]) => <div key={event} className="flex gap-3 border-t border-slate-200/60 py-3 first:border-t-0 first:pt-0"><div className="mt-1 h-2.5 w-2.5 rounded-full bg-[#176B5B]" /><div><div className="text-[14px] font-bold text-slate-900">{event}</div><div className="text-[12px] text-slate-500">{time}</div></div></div>)}</Card>;
}

function DraftReplyScreen() {
  return (
    <Phone title="Draft Reply" subtitle="Polite · English · Ready to copy" activeTab="Tasks">
      <div className="space-y-4">
        <Card>
          <div className="mb-3 flex items-center justify-between gap-3">
            <div className="flex gap-2"><Pill>Polite</Pill><Pill>English</Pill></div>
            <button className="inline-flex h-9 shrink-0 items-center gap-1.5 rounded-full border border-white/75 bg-white/56 px-3 text-[12px] font-black text-[#176B5B] shadow-sm backdrop-blur-xl">
              <Copy size={14} /> Copy
            </button>
          </div>
          <div className="rounded-3xl border border-white/70 bg-white/42 p-4 text-[15px] leading-6 text-slate-700 backdrop-blur-xl">
            Hi, I noticed that I was charged for my subscription on May 24. I have now cancelled it, but I would be grateful if you could consider a refund for the latest charge.
          </div>
        </Card>
        <Card>
          <h3 className="text-[17px] font-black text-slate-950">Did you send it?</h3>
          <p className="mt-1 text-[13px] leading-5 text-slate-500">Mark it sent so OneDone can help you follow up.</p>
          <div className="mt-4 grid grid-cols-2 gap-3"><Button variant="soft">Yes, sent</Button><Button variant="secondary">Not yet</Button></div>
        </Card>
      </div>
    </Phone>
  );
}

function ReminderScreen() {
  return (
    <Phone title="Reminder" subtitle="Set a gentle follow-up." activeTab="Tasks">
      <div className="space-y-4"><IllustrationCard title="Don’t hold it all in your head" subtitle="A local reminder first, backend sync after scheduling." /><Card className="space-y-4"><Field label="Reminder title" value="Follow up about refund" /><Field label="Date and time" value="Tomorrow · 9:00 AM" /><Field label="Note" type="textarea" value="If support has not replied, send a short follow-up." /></Card><div className="flex flex-col items-center gap-3"><Button icon={CalendarClock} className="w-full max-w-[260px]">Save reminder</Button><Button variant="secondary" className="w-full max-w-[260px]">Cancel</Button></div></div>
    </Phone>
  );
}

function LimitedScreen() {
  return (
    <Phone title="Limited mode" subtitle="Your saved work is still here." activeTab="Home">
      <div className="space-y-4"><Card className="bg-rose-100/70"><Pill tone="danger" icon={Lock}>Starter ended</Pill><h2 className="mt-4 text-[22px] font-black tracking-[-0.04em] text-slate-950">New tasks are locked.</h2><p className="mt-2 text-[14px] leading-6 text-slate-600">You can still view saved tasks, copy old replies, update existing reminders, and restore purchases.</p></Card><Card><div className="text-[15px] font-black text-slate-900">Still available</div><div className="mt-3 space-y-3 text-[14px] text-slate-600"><div className="flex gap-2"><CheckCircle2 size={17} className="text-[#176B5B]" /> View existing tasks</div><div className="flex gap-2"><CheckCircle2 size={17} className="text-[#176B5B]" /> Copy saved outputs</div><div className="flex gap-2"><CheckCircle2 size={17} className="text-[#176B5B]" /> Restore purchases</div></div></Card><div className="flex flex-col items-center gap-3"><Button icon={Lock} className="w-full max-w-[260px]">Start 14-day trial</Button><Button variant="secondary" className="w-full max-w-[260px]">Restore purchases</Button></div></div>
    </Phone>
  );
}

function SubscriptionScreen() {
  return (
    <Phone title="Keep using OneDone" subtitle="Your Starter Access has ended." footer={false}>
      <div className="flex h-full flex-col justify-between pb-4"><div className="space-y-4"><IllustrationCard title="Start your trial" subtitle="Apple purchase sheet opens next." /><Card><h1 className="text-[30px] font-black leading-[1] tracking-[-0.06em] text-slate-950">Start your 14-day App Store trial.</h1><p className="mt-3 text-[15px] leading-6 text-slate-600">Keep using task breakdowns, replies, reminders, and follow-ups.</p></Card><Card>{["Create new tasks", "Generate replies", "Set follow-up reminders", "Keep saved tasks"].map((item) => <div key={item} className="flex items-center gap-3 border-t border-slate-200/60 py-3 first:border-t-0 first:pt-0 text-[14px] text-slate-600"><CheckCircle2 size={17} className="text-[#176B5B]" />{item}</div>)}</Card></div><div className="space-y-3"><div className="flex flex-col items-center gap-3"><Button icon={WalletCards} className="w-full max-w-[260px]">Start 14-day trial</Button><Button variant="secondary" className="w-full max-w-[260px]">Restore purchases</Button></div><div className="text-center text-[12px] text-slate-500">Terms of Use · Privacy Policy</div></div></div>
    </Phone>
  );
}

function AccessScreen() {
  return (
    <Phone title="Access" subtitle="Your current OneDone access state." activeTab="Settings">
      <div className="space-y-4"><Card><Pill tone="good" icon={ShieldCheck}>Starter active</Pill><h2 className="mt-4 text-[24px] font-black tracking-[-0.05em] text-slate-950">3 days to try the full loop.</h2><p className="mt-2 text-[14px] leading-6 text-slate-500">After Starter Access ends, creation actions move behind the App Store trial gate.</p></Card><Card>{["AI actions today", "Task creation", "Draft replies", "Reminders"].map((item, index) => <div key={item} className="flex items-center justify-between border-t border-slate-200/60 py-3 first:border-t-0 first:pt-0 text-[14px]"><span className="font-bold text-slate-800">{item}</span><span className="text-slate-500">{index === 0 ? "4 / 10" : "Available"}</span></div>)}</Card></div>
    </Phone>
  );
}

function SettingsScreen() {
  return (
    <Phone title="Settings" subtitle="Account, access, preferences, and privacy." activeTab="Settings">
      <div className="space-y-4"><Card><div className="text-[15px] font-black text-slate-900">Account</div><div className="mt-3 rounded-3xl bg-white/42 p-4 text-[14px] text-slate-600">karina@example.com</div></Card><Card><div className="mb-2 text-[15px] font-black text-slate-900">Access</div><div className="space-y-3"><div className="flex items-center justify-between text-[14px]"><span>Starter Access</span><Pill tone="warn">Ended</Pill></div><div className="flex items-center justify-between text-[14px]"><span>Subscription</span><span className="text-slate-500">Not active</span></div></div></Card>{["Default reply tone", "Language", "Notification settings", "Privacy Policy", "Delete all data", "Log out"].map((item) => <div key={item} className="flex items-center justify-between rounded-3xl border border-white/70 bg-white/58 p-4 text-[14px] font-bold text-slate-900 shadow-sm backdrop-blur-2xl">{item}<ChevronRight size={17} className="text-slate-400" /></div>)}</div>
    </Phone>
  );
}

function EdgeStatesScreen() {
  return (
    <Phone title="Edge states" subtitle="Recoverable, calm, never scary." activeTab="Home">
      <div className="space-y-4"><Card className="bg-orange-100/70"><Pill tone="warn" icon={AlertTriangle}>Rate limited</Pill><h2 className="mt-4 text-[20px] font-black tracking-[-0.04em] text-slate-950">You’ve used today’s AI actions.</h2><p className="mt-2 text-[14px] leading-6 text-slate-600">You can still view saved tasks. Try again tomorrow or start your trial to continue.</p></Card><Card><Pill tone="info">Offline</Pill><h2 className="mt-4 text-[20px] font-black text-slate-950">Saved tasks are available.</h2><p className="mt-2 text-[14px] leading-6 text-slate-500">New tasks and changes need internet connection.</p></Card><Card className="bg-rose-100/70"><Pill tone="danger" icon={XCircle}>Permission needed</Pill><p className="mt-3 text-[14px] leading-6 text-slate-600">Notifications are off. Turn them on to schedule reminders from OneDone.</p></Card></div>
    </Phone>
  );
}

const screenMap = {
  Auth: AuthScreen,
  Onboarding: OnboardingScreen,
  "Starter Intro": StarterIntroScreen,
  Home: HomeScreen,
  Templates: TemplatesScreen,
  "New Task": NewTaskScreen,
  Loading: LoadingScreen,
  Clarification: ClarificationScreen,
  "Task Result": TaskResultScreen,
  "My Tasks Empty": MyTasksEmptyScreen,
  "My Tasks": MyTasksScreen,
  "Task Detail": TaskDetailScreen,
  "Draft Reply": DraftReplyScreen,
  Reminder: ReminderScreen,
  Limited: LimitedScreen,
  Subscription: SubscriptionScreen,
  Access: AccessScreen,
  Settings: SettingsScreen,
  "Edge States": EdgeStatesScreen,
};

function ComponentPreview() {
  return (
    <div className="rounded-[36px] border border-white/75 bg-white/54 p-6 shadow-[0_22px_60px_rgba(37,50,44,0.12)] backdrop-blur-3xl">
      <div className="mb-4 flex items-center justify-between">
        <div><div className="text-[24px] font-black tracking-[-0.04em] text-slate-950">Component language</div><p className="mt-1 text-sm text-slate-500">Glass, but quiet. Modern iOS feel without purple or AI clichés.</p></div>
        <Pill tone="good">iOS 26-inspired</Pill>
      </div>
      <div className="grid gap-4 md:grid-cols-3"><Card><div className="text-sm font-black">Primary action</div><div className="mt-4"><Button>Continue</Button></div></Card><Card><div className="text-sm font-black">Status badges</div><div className="mt-4 flex flex-wrap gap-2"><Pill tone="good">Active</Pill><Pill tone="warn">Waiting</Pill><Pill tone="danger">Locked</Pill></div></Card><IllustrationCard title="Guided help" subtitle="Graphical cues, not charts." /></div>
    </div>
  );
}

export default function OneDoneDesignPrototype() {
  const [active, setActive] = useState("Home");
  const ActiveScreen = screenMap[active];
  return (
    <div className="min-h-screen bg-[#EEF3F0] px-5 py-8 text-slate-950">
      <div className="mx-auto max-w-7xl">
        <header className="mb-8 overflow-hidden rounded-[40px] border border-white/75 bg-white/52 p-6 shadow-[0_24px_80px_rgba(37,50,44,0.13)] backdrop-blur-3xl md:p-8">
          <div className="relative"><div className="absolute -right-20 -top-20 h-64 w-64 rounded-full bg-emerald-200/40 blur-3xl" /><div className="absolute bottom-0 right-44 h-44 w-44 rounded-full bg-orange-200/40 blur-3xl" /><div className="relative flex flex-col gap-6 md:flex-row md:items-end md:justify-between"><div><Pill tone="good">OneDone visual direction</Pill><h1 className="mt-4 max-w-3xl text-[44px] font-black leading-[0.94] tracking-[-0.07em] md:text-[68px]">One small thing, done.</h1><p className="mt-5 max-w-2xl text-[16px] leading-7 text-slate-600">A modern, glassy, calm iOS design concept for a guided self-service assistant. Practical admin help, not chatbot magic.</p></div><div className="rounded-[30px] border border-white/75 bg-white/54 p-4 text-sm leading-6 text-slate-600 backdrop-blur-2xl md:w-[380px]"><strong className="text-slate-950">Navigation:</strong> task creation lives only in the elevated circular + button in the bottom tab bar.</div></div></div>
        </header>

        <div className="mb-8 flex flex-wrap gap-2">{screenNames.map((screen) => <button key={screen} onClick={() => setActive(screen)} className={`rounded-full border px-4 py-2 text-sm font-bold backdrop-blur-xl ${active === screen ? "border-[#176B5B] bg-[#176B5B] text-white" : "border-white/70 bg-white/54 text-slate-600"}`}>{screen}</button>)}</div>

        <div className="grid gap-8 lg:grid-cols-[430px_1fr]">
          <div className="lg:sticky lg:top-8 lg:h-fit"><ActiveScreen /></div>
          <div className="space-y-8"><ComponentPreview /><div className="rounded-[36px] border border-white/75 bg-white/48 p-6 shadow-[0_22px_60px_rgba(37,50,44,0.10)] backdrop-blur-3xl"><div className="mb-5 flex items-center justify-between"><div><h2 className="text-[26px] font-black tracking-[-0.04em]">Prototype flow notes</h2><p className="mt-1 text-sm text-slate-500">Key product paths represented in the visual system.</p></div><Pill>390 × 844</Pill></div><div className="grid gap-4 md:grid-cols-2">{[["New user", "Auth → Onboarding → Starter Intro → Home → tap + → New Task"], ["Clarification", "+ New Task → Clarification → Task Result → Task Detail"], ["Reply", "Task Detail → Draft Reply → Copy → Mark Sent → Waiting"], ["Expired", "Limited Home → Subscription Gate → StoreKit → Access refresh"]].map(([title, flow]) => <div key={title} className="rounded-3xl border border-white/70 bg-white/48 p-4 backdrop-blur-xl"><div className="font-black">{title}</div><div className="mt-1 text-sm leading-6 text-slate-500">{flow}</div></div>)}</div></div><div className="rounded-[36px] border border-white/75 bg-white/48 p-6 shadow-[0_22px_60px_rgba(37,50,44,0.10)] backdrop-blur-3xl"><h2 className="text-[26px] font-black tracking-[-0.04em]">Screen coverage</h2><p className="mt-1 text-sm text-slate-500">All core MVP states are represented. Use the selector above for full-size review.</p><div className="mt-5 grid gap-4 md:grid-cols-3">{screenNames.map((screen) => <div key={screen} className="rounded-3xl border border-white/70 bg-white/44 p-4 text-sm font-bold text-slate-700 backdrop-blur-xl">{screen}</div>)}</div></div></div>
        </div>
      </div>
    </div>
  );
}
