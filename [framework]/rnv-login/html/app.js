const post = (name, data) => fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
}).then((r) => r.json());

Vue.createApp({
    data() {
        return { view: null, name: '', busy: false };
    },
    methods: {
        async confirm() {
            if (this.busy) return;
            this.busy = true;
            await post('nickname', { name: this.name.trim() });
            this.busy = false;
        },
        play() { post('play'); },
    },
    mounted() {
        window.addEventListener('message', (e) => {
            const a = e.data.action;
            if (a === 'nickname') {
                this.view = 'nickname';
                this.$nextTick(() => this.$refs.input && this.$refs.input.focus());
            } else if (a === 'play') {
                this.view = 'play';
            } else if (a === 'hide') {
                this.view = null;
            }
        });
    },
}).mount('#app');
