const CARDINALS = { 0: 'N', 45: 'NE', 90: 'E', 135: 'SE', 180: 'S', 225: 'SW', 270: 'W', 315: 'NW' };
const REM_PER_DEG = 0.35; // 15 degrees = 5.25rem
const HALF_RANGE = 70;

let nextId = 1;

// "text [[highlight]] text" -> [{ text, hl }]
function parseText(text) {
    return text.split(/(\[\[.*?\]\])/).filter(Boolean).map((t) => (
        t.startsWith('[[') ? { text: t.slice(2, -2), hl: true } : { text: t, hl: false }
    ));
}

Vue.createApp({
    data() {
        return {
            hud: { show: false, name: '', fps: 0, ping: 0, heading: 0, health: 100, armor: 0, talking: false, showFps: true, showPing: true, keys: true, party: 0, armorMax: 0, mates: [], myColor: false, myLeader: false, weapons: [], notoriety: false, role: 'civilian' },
            notifications: [],
            progress: null,
            jail: null,
            hits: [], // damage numbers { id, x, y, amount }
            tags: [], // head names { x, y, name, dot, role }
            prompt: null,
            marks: [], // small diamonds on interaction points { x, y }
            picks: [], // pickup feed cards { id, text, image, color }
            icons: {
                card: 'M2 6h16v3H2V6zm0 5h16v5H2v-5zm2 2v1h5v-1H4zm15-1h2v2h2v2h-2v2h-2v-2h-2v-2h2v-2z',
                speak: 'M4 4h16a2 2 0 012 2v9a2 2 0 01-2 2h-7l-5 4v-4H4a2 2 0 01-2-2V6a2 2 0 012-2zm3 6.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3zm5 0a1.5 1.5 0 100 3 1.5 1.5 0 000-3zm5 0a1.5 1.5 0 100 3 1.5 1.5 0 000-3z',
                cash: 'M2 5h20v12H2V5zm2 2v8h16V7H4zm8 1.5a2.5 2.5 0 110 5 2.5 2.5 0 010-5zM6 19h12v1.5H6V19z',
            },
        };
    },
    computed: {
        armed() { return this.hud.role === 'criminal' || this.hud.role === 'cop'; },
        compassMarks() {
            const h = this.hud.heading;
            const marks = [];
            const start = Math.ceil((h - HALF_RANGE) / 15) * 15;
            for (let a = start; a <= h + HALF_RANGE; a += 15) {
                const angle = ((a % 360) + 360) % 360;
                const d = a - h;
                marks.push({
                    angle: a,
                    label: CARDINALS[angle] || String(angle),
                    cardinal: angle % 45 === 0,
                    x: 36.75 + d * REM_PER_DEG,
                    opacity: 1 - Math.pow(Math.abs(d) / HALF_RANGE, 2) * 0.7,
                });
            }
            return marks;
        },
    },
    methods: {
        weapon(n) { return this.hud.weapons[n - 1] || null; },
        clock(s) {
            const m = Math.floor(s / 60);
            const r = s % 60;
            return `${m < 10 ? '0' : ''}${m}:${r < 10 ? '0' : ''}${r}`;
        },
        addNotify(d) {
            const n = { id: nextId++, tag: d.id, parts: parseText(d.text), color: d.color, countdown: d.countdown, keys: d.keys };
            this.notifications.push(n);
            const timer = n.countdown !== undefined ? setInterval(() => {
                const item = this.notifications.find((x) => x.id === n.id);
                if (item && item.countdown > 0) item.countdown -= 1;
            }, 1000) : null;
            setTimeout(() => {
                if (timer) clearInterval(timer);
                this.notifications = this.notifications.filter((x) => x.id !== n.id);
            }, d.duration);
        },
        startProgress(d) {
            this.progress = { label: d.label, width: 0, duration: d.duration };
            // next frame so the CSS transition runs from 0 to 100
            requestAnimationFrame(() => requestAnimationFrame(() => {
                if (this.progress) this.progress.width = 100;
            }));
        },
    },
    mounted() {
        window.addEventListener('message', (e) => {
            const d = e.data;
            if (d.action === 'hud') {
                for (const k in d) if (k !== 'action') this.hud[k] = d[k];
            } else if (d.action === 'notify') {
                this.addNotify(d);
            } else if (d.action === 'notify:remove') {
                this.notifications = this.notifications.filter((x) => x.tag !== d.id);
            } else if (d.action === 'progress') {
                this.startProgress(d);
            } else if (d.action === 'progress:stop') {
                this.progress = null;
            } else if (d.action === 'tags') {
                this.tags = d.tags;
            } else if (d.action === 'damage') {
                const hit = { id: Date.now() + Math.random(), x: d.x, y: d.y, amount: d.amount };
                this.hits.push(hit);
                setTimeout(() => { this.hits = this.hits.filter((h) => h.id !== hit.id); }, 700);
            } else if (d.action === 'jail') {
                this.jail = d.years === undefined ? null : d.years;
            } else if (d.action === 'pickup') {
                // newest at the bottom; more than 3 -> the oldest (top) leaves
                const card = { id: Date.now() + Math.random(), text: d.text, image: d.image, color: d.color };
                this.picks.push(card);
                while (this.picks.length > 3) this.picks.shift();
                setTimeout(() => { this.picks = this.picks.filter((c) => c.id !== card.id); }, 4500); // by id: Vue proxies
            } else if (d.action === 'marks') {
                this.marks = d.marks;
            } else if (d.action === 'prompt') {
                this.prompt = d.prompt;
            }
        });
    },
}).mount('#app');
