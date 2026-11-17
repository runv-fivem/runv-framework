const post = (name, data) => fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
});

Vue.createApp({
    data() {
        return { open: false, myId: '', search: '', party: null, max: 3 };
    },
    computed: {
        members() { return this.party ? this.party.members : []; },
    },
    methods: {
        invite() {
            const id = this.search.trim();
            if (!id) return;
            post('party:invite', { id });
            this.search = '';
        },
        // Own slot = leave. The leader can remove the others
        canRemove(m) {
            if (!m) return false;
            return m.uid === this.myId || (this.party && this.party.leader);
        },
        remove(m) {
            if (m.uid === this.myId) post('party:leave');
            else post('party:kick', { uid: m.uid });
        },
        copyId() {
            const t = document.createElement('textarea');
            t.value = String(this.myId);
            document.body.appendChild(t);
            t.select();
            document.execCommand('copy');
            t.remove();
        },
        close() { post('party:close'); },
    },
    mounted() {
        window.addEventListener('message', (e) => {
            const d = e.data;
            if (d.action === 'party:open') {
                this.myId = d.myId;
                this.search = '';
                this.open = true;
            } else if (d.action === 'party:update') {
                this.party = d.party;
                this.max = d.max;
            } else if (d.action === 'party:close') {
                this.open = false;
            }
        });
        window.addEventListener('keydown', (e) => {
            if (this.open && e.key === 'Escape') this.close();
        });
    },
}).mount('#app');
