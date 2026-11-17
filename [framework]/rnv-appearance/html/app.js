const post = (name, data) => fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
});

Vue.createApp({
    data() {
        return {
            open: false,
            tab: 'face',
            gender: 'male',
            state: {},
            counts: { face: 0, hair: 0, beard: 0, scar: 0 },
            skin: [],
            eye: [],
            palette: [],
        };
    },
    computed: {
        tabs() { return this.gender === 'male' ? ['face', 'hair', 'beard', 'scar'] : ['face', 'hair', 'scar']; },
        tileKey() { return this.tab; },
        colorKey() { return this.tab === 'hair' ? 'hairColor' : 'beardColor'; },
    },
    methods: {
        select(key, index) {
            this.state[key] = index;
            post('creator:select', { key, index });
        },
        setGender(gender) {
            if (gender !== this.gender) post('creator:gender', { gender });
        },
        confirm() { post('creator:confirm'); },
        quit() { post('creator:quit'); },
    },
    mounted() {
        window.addEventListener('message', (e) => {
            const d = e.data;
            if (d.action === 'creator:open') {
                this.gender = d.gender;
                this.state = d.state;
                this.counts = d.counts;
                this.skin = d.skin;
                this.eye = d.eye;
                this.palette = d.palette;
                if (!this.tabs.includes(this.tab)) this.tab = 'face';
                this.open = true;
            } else if (d.action === 'creator:close') {
                this.open = false;
                this.tab = 'face';
            }
        });
        window.addEventListener('keydown', (e) => {
            if (!this.open) return;
            if (e.key === 'e' || e.key === 'E') this.confirm();
            else if (e.key === 'Escape') this.quit();
        });
    },
}).mount('#app');
