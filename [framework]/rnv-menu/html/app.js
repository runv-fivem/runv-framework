const post = (name, data) => fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
});

Vue.createApp({
    data() {
        return { open: false, tabs: [], tab: null, values: {}, defaults: {}, selected: null, pause: null, pauseSel: null, gtaSections: {}, gtaRows: {}, keymap: null, capSlot: null, warning: null };
    },
    computed: {
        // RNV rows of the tab, then the GTA pages of that tab (section header + rows read from GTA)
        currentRows() {
            const t = this.tabs.find((x) => x.id === this.tab);
            const rows = t ? t.rows.slice() : [];
            for (const s of this.gtaSections[this.tab] || []) {
                const gta = this.gtaRows[s.page];
                if (!gta || !gta.length) continue;
                rows.push({ section: s.title });
                rows.push(...gta);
            }
            return rows;
        },
        keyCategories() { return this.keymap ? this.keymap.categories.filter((c) => !c.restore) : []; },
        categoryLabel() {
            const c = this.keyCategories.find((x) => x.index === this.keymap.category);
            return c ? c.label : '';
        },
        restoreLabel() {
            const c = this.keymap && this.keymap.categories.find((x) => x.restore);
            return c ? c.label : '';
        },
        selectedRow() { return this.currentRows.find((r) => r.key && r.key === this.selected) || this.currentRows.find((r) => r.key); },
        pauseButtons() {
            const b = [];
            if (this.pause.party) b.push({ id: 'party', label: 'PARTY' });
            if (this.pause.clan) b.push({ id: 'clan', label: 'CLAN' });
            b.push({ id: 'settings', label: 'SETTINGS' }, { id: 'exit', label: 'EXIT' });
            return b;
        },
    },
    methods: {
        enabled(row) {
            return !row.disabled && (!row.enabledWhen || this.values[row.enabledWhen.key] === row.enabledWhen.value);
        },
        step(row, dir) {
            if (row.gta) return this.gtaStep(row, dir);
            const i = row.options.indexOf(this.values[row.key]);
            this.values[row.key] = row.options[(i + dir + row.options.length) % row.options.length];
        },
        // GTA rows change in GTA at once; GTA sends the rows back (settings:gtaRows)
        gtaStep(row, dir) {
            if (row.gta.codeBuilt) return post('settings:gtaStep', { tab: row.gta.tab, prefId: row.gta.prefId, direction: dir });
            const n = row.options.length;
            const index = (row.index + dir + n) % n;
            this.values[row.key] = row.options[index];
            post('settings:gtaSet', { tab: row.gta.tab, prefId: row.gta.prefId, value: index });
        },
        act(row) { post('settings:gtaTrigger', { tab: row.gta.tab, row: row.gta.row }); },
        keyCategory(dir) {
            const list = this.keyCategories;
            const i = list.findIndex((c) => c.index === this.keymap.category);
            const next = list[(i + dir + list.length) % list.length];
            post('settings:keymap', { category: next.index });
        },
        rebind(k, slot) {
            if (!k.mappable || this.capSlot) return;
            this.capSlot = k.row + ':' + slot;
            post('settings:rebind', { row: k.row, slot });
        },
        clearKeys(k) {
            if (!k.mappable) return;
            post('settings:clearKey', { row: k.row, slot: 0 });
            post('settings:clearKey', { row: k.row, slot: 1 });
        },
        restoreKeys() { post('settings:restoreKeys'); },
        answer(choice) {
            this.warning = null;
            post('settings:answer', { choice });
        },
        slid(row) {
            if (row.gta) post('settings:gtaSet', { tab: row.gta.tab, prefId: row.gta.prefId, value: this.values[row.key] });
        },
        toggle(row) { this.values[row.key] = !this.values[row.key]; },
        fill(row) { return ((this.values[row.key] - row.min) / (row.max - row.min)) * 100 + '% 100%'; },
        number(row) { return ((this.values[row.key] - row.min) / (row.max - row.min)).toFixed(2); },
        confirm() { post('settings:confirm', this.values); },
        back() { post('settings:back'); },
        reset() { this.values = Object.assign({}, this.values, this.defaults); post('settings:default'); },
        pausePost(id) { post('pause:' + id); },
        copyUid() {
            const t = document.createElement('textarea');
            t.value = String(this.pause.uid);
            document.body.appendChild(t);
            t.select();
            document.execCommand('copy');
            t.remove();
        },
    },
    watch: {
        tab(t) { if (t === 'keys' && !this.keymap) post('settings:keymap', { category: 0 }); },
    },
    mounted() {
        window.addEventListener('message', (e) => {
            const d = e.data;
            if (d.action === 'settings:open') {
                this.tabs = d.tabs;
                this.values = Object.assign({}, d.values);
                this.defaults = d.defaults;
                if (!this.tab) this.tab = d.tabs[0].id;
                this.selected = null;
                this.gtaSections = d.sections || {};
                this.gtaRows = {};
                this.keymap = null;
                this.capSlot = null;
                this.warning = null;
                this.open = true;
                if (this.tab === 'keys') post('settings:keymap', { category: 0 });
            } else if (d.action === 'settings:keymap') {
                this.keymap = d.page;
            } else if (d.action === 'settings:capturing') {
                if (!d.on) this.capSlot = null;
            } else if (d.action === 'settings:gtaWarning') {
                this.warning = d;
            } else if (d.action === 'settings:tab') { // dev: switch tab / scroll the rows
                this.tab = d.tab;
                this.$nextTick(() => { document.querySelector('.rows').scrollTop = d.scroll || 0; });
            } else if (d.action === 'settings:gta') {
                this.gtaSections = d.sections;
            } else if (d.action === 'settings:gtaRows') {
                for (const r of d.rows) this.values[r.key] = r.value;
                this.gtaRows[d.tab] = d.rows;
            } else if (d.action === 'settings:close') {
                this.open = false;
            } else if (d.action === 'pause:open') {
                this.pause = d;
                this.pauseSel = null;
            } else if (d.action === 'pause:close') {
                this.pause = null;
            } else if (d.action === 'pause:url') {
                window.invokeNative('openUrl', d.url);
            }
        });
        window.addEventListener('keydown', (e) => {
            if (this.pause && e.key === 'Escape') return this.pausePost('close');
            if (!this.open) return;
            if (this.capSlot) return; // the game is waiting for the new key
            if (this.warning) {
                if (e.key === 'Enter') this.answer('yes');
                else if (e.key === 'Escape') this.answer('no');
                else if (e.key === ' ' && this.warning.alt) this.answer('alt');
                return;
            }
            if (e.key === 'Enter') this.confirm();
            else if (e.key === 'Escape') this.back();
            else if (e.key === 'r' || e.key === 'R') this.reset();
        });
    },
}).mount('#app');
