// RUN V inventory UI (Vue, no build step). Same NUI protocol as rnv-inventory's original UI:
//   from Lua: init, setupInventory, refreshSlots, closeInventory, setInventoryVisible, ataCatalog, market
//   to Lua:   uiLoaded, swapItems, useItem, exit, marketAction
// Grid: 6 columns, slot N = cell, an item sits at its top-left slot and covers size { w, h } (server checks the same rules)

const COLS = 6;
const GRID = 54;
const SLOT_W1 = 55, SLOT_W2 = 56, SLOT_ARMOR = 57, SLOT_BAG = 58, SLOT_POUCH = 59, POUCH_FIRST = 60;
const CELL_REM = 7.6; // cell 7.5rem + 0.1rem gap
const MONEY_STACK = 25000; // Extras.MoneyStack

const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'rnv-inventory';
const isBrowser = !window.invokeNative;

async function post(name, data) {
    if (isBrowser) return true;
    const resp = await fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data === undefined ? {} : data),
    });
    return resp.json();
}

function toSlotMap(items) {
    const map = {};
    for (const key in items || {}) {
        const item = items[key];
        if (item && item.name) map[item.slot] = item;
    }
    return map;
}

function remPx() {
    return window.innerHeight / 108;
}

// ---------- GSAP (from the user's Inventory_redesign): drag ghost and drop pop ----------
const still = !window.gsap;
if (!still) gsap.config({ nullTargetWarn: false });
// The dragged item trails the cursor a little and leans into the direction it is moving
const ghost = { x: null, y: null, tilt: null, lastX: 0 };
function moveGhost(x, y, first) {
    const el = document.querySelector('.ghost');
    if (!el) return;
    if (still) { el.style.transform = `translate(${x}px, ${y}px)`; return; }
    if (first) {
        gsap.set(el, { x, y, rotation: 0 });
        gsap.fromTo(el, { scale: 0.5 }, { scale: 1, duration: 0.25, ease: 'back.out(2.2)' });
        Object.assign(ghost, {
            x: gsap.quickTo(el, 'x', { duration: 0.14, ease: 'power3' }),
            y: gsap.quickTo(el, 'y', { duration: 0.14, ease: 'power3' }),
            tilt: gsap.quickTo(el, 'rotation', { duration: 0.35, ease: 'power2' }),
            lastX: x,
        });
    }
    ghost.x(x);
    ghost.y(y);
    ghost.tilt(Math.max(-16, Math.min(16, (x - ghost.lastX) * 1.6)));
    ghost.lastX = x;
}
// The item lands in its new cell with a small bounce
function popItem(key) {
    const el = document.querySelector(`[data-key="${key}"]`);
    if (still || !el) return;
    gsap.fromTo(el, { scale: 1.18 }, { scale: 1, duration: 0.32, ease: 'back.out(3)', clearProps: 'transform' });
}
// Windows rise in like the redesign's modal
function popModal() {
    const el = document.querySelector('.modal');
    if (still || !el) return;
    gsap.from(el, { opacity: 0, duration: 0.2, clearProps: 'opacity' });
    gsap.from(el.querySelectorAll('.mband, .mbar'), { y: 32, scale: 0.96, duration: 0.4, ease: 'back.out(1.6)', clearProps: 'transform' });
}

Vue.createApp({
    data() {
        return {
            visible: false,
            left: { id: null, type: 'player', slots: 63, items: {} },
            right: null,
            items: {},
            imagepath: 'nui://rnv-inventory/web/images',
            catalog: { tier: {}, bags: {}, baseRows: 2 },
            drag: null,
            hover: null,
            tip: null,
            mouse: { x: 0, y: 0 },
            busy: false,
            market: null, // RUN V Black Market / Suspicious Door data from rnv-blackmarket
            dealSel: 0,
            bmTab: 'GEAR',
            deskTab: 'storage',
            deskTake: 0,
            dealTip: null,
            modal: null, // { kind: 'destroy'|'split'|'buy', title, ... }
            // ghost = grey picture shown while the slot is empty
            fixed: [
                { slot: SLOT_W1, cls: 'w1', ghost: 'rc_5_56_mk1' }, { slot: SLOT_W2, cls: 'w2', ghost: 'dp_9_mk1' },
                { slot: SLOT_ARMOR, cls: 'armor', ghost: 'light_body_armor' }, { slot: SLOT_BAG, cls: 'bag', ghost: 'sports_bag_2' },
                { slot: SLOT_POUCH, cls: 'pouch', ghost: 'versatile_pouch_1' },
                { slot: 60, cls: 'pc pc1' }, { slot: 61, cls: 'pc pc2' }, { slot: 62, cls: 'pc pc3' }, { slot: 63, cls: 'pc pc4' },
            ],
        };
    },

    computed: {
        // A real container on the left (trunk, stash, shop...). There are no ground drops
        container() {
            return this.right && this.right.type !== 'newdrop' && this.right.type !== 'drop' ? this.right : null;
        },
        rightTitle() {
            if (!this.right) return '';
            return this.right.label || (this.right.type === 'newdrop' ? 'Drop' : this.right.type);
        },
        // Fence deal: item cost, sale bonus = Notoriety + 1% per `per` $ (max `max`), total
        fence() {
            const m = this.market;
            if (!m || m.mode !== 'fence' || !this.right) return { cost: 0, growth: 0, pct: 0, bonus: 0, total: 0 };
            let cost = 0;
            for (const slot in this.right.items) {
                const item = this.right.items[slot];
                cost += (m.values[item.name] || 0) * item.count;
            }
            const growth = Math.min(m.max || 0, Math.floor(cost / (m.per || 1)));
            const pct = (m.bonus || 0) + growth;
            const bonus = Math.floor(cost * pct / 100);
            return { cost, growth, pct, bonus, total: cost + bonus };
        },
        fenceTotal() { return this.fence.total; },
        showPrices() { return !!(this.market && this.market.mode === 'fence'); },
        deskDropClass() {
            if (!this.drag || !this.hover || this.hover.side !== 'desk') return {};
            return this.drag.item.name === 'money' ? { ok: true } : { bad: true };
        },
        ghostSize() {
            const [w, h] = this.sizeOf(this.drag.item.name);
            return { width: `calc(${w * CELL_REM}rem - var(--gap))`, height: `calc(${h * CELL_REM}rem - var(--gap))` };
        },
        previewStyle() {
            return this.itemStyle({ ...this.drag.item, slot: this.target.slot }, true);
        },
        rangeFill() {
            const m = this.modal;
            const pct = m.max > m.min ? ((m.value - m.min) / (m.max - m.min)) * 100 : 100;
            return { background: `linear-gradient(90deg, #c5ff39 ${pct}%, #d9d6cf ${pct}%)` };
        },
        modalOkText() {
            const m = this.modal;
            if (m.kind === 'destroy') return 'DESTROY';
            if (m.kind === 'split') return 'SPLIT';
            return 'BUY $' + this.fmt(m.price * m.value);
        },
        tipStyle() {
            return { left: (this.mouse.x + 18) + 'px', top: (this.mouse.y + 18) + 'px' };
        },
        // Where the dragged item would land: { side, slot, cells: Set, ok }
        target() {
            if (!this.drag || !this.hover) return null;
            const { side, slot } = this.hover;
            if (side === 'plot' || side === 'desk') return null;
            const item = this.drag.item;

            if (side === 'left' && slot > GRID) {
                return { side, slot, cells: new Set([slot]), ok: this.fixedFits(slot, item) };
            }

            const [w, h] = this.sizeOf(item.name);
            const hx = (slot - 1) % COLS - this.drag.cellX;
            const hy = Math.floor((slot - 1) / COLS) - this.drag.cellY;
            if (hx < 0 || hy < 0) return { side, slot, cells: new Set([slot]), ok: false };

            const top = hy * COLS + hx + 1;
            const cells = new Set();
            for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) cells.add(top + y * COLS + x);
            return { side, slot: top, cells, ok: this.gridFits(side, top, item) };
        },
    },

    methods: {
        // ---------- data helpers ----------
        inv(side) { return side === 'left' ? this.left : this.right; },
        typeOf(side) { return side === 'left' ? 'player' : this.right.type; },
        sizeOf(name) {
            const size = this.items[name] && this.items[name].size;
            return size ? [size[0], size[1]] : [1, 1];
        },
        label(item) { return (item.metadata && item.metadata.label) || (this.items[item.name] && this.items[item.name].label) || item.name; },
        // sell price from the item data (rnv.sell)
        price(item) { const d = this.items[item.name]; return d && d.rnv && d.rnv.sell ? d.rnv.sell : 0; },
        description(item) { return (item.metadata && item.metadata.description) || (this.items[item.name] && this.items[item.name].description) || ''; },
        image(item) {
            const meta = item.metadata;
            if (meta && meta.imageurl) return meta.imageurl;
            if (meta && meta.image) return `${this.imagepath}/${meta.image}.png`;
            const data = this.items[item.name];
            if (data && data.image) return data.image.indexOf('://') > 0 ? data.image : `${this.imagepath}/${data.image}`;
            return `${this.imagepath}/${item.name}.png`;
        },
        rarity(item) {
            const tier = this.catalog.tier[item.name] || 0;
            return tier === -1 ? 'white' : tier >= 4 ? 'red' : tier === 3 ? 'gold' : tier === 2 ? 'purple' : 'green';
        },
        fmt(n) { return Math.floor(n || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.'); },
        cashIn(inv) {
            let total = 0;
            for (const slot in inv.items) if (inv.items[slot].name === 'money') total += inv.items[slot].count;
            return total;
        },
        countText(item) {
            if (item.name === 'money') return '$' + this.fmt(item.count);
            if (item.metadata && item.metadata.ammo !== undefined && this.items[item.name] && this.items[item.name].weapon) return item.metadata.ammo;
            return item.count > 1 ? this.fmt(item.count) : '';
        },
        durability(item) {
            const meta = item.metadata;
            if (!meta || meta.durability === undefined) return null;
            let d = meta.durability;
            if (d > 100 && meta.degrade) d = ((meta.durability - Date.now() / 1000) / (60 * meta.degrade)) * 100;
            return Math.max(0, Math.min(100, Math.round(d)));
        },
        bagInfo(name) { return name && this.catalog.bags[name]; },
        openRows(side) {
            if (side !== 'left') return Math.ceil(this.right.slots / COLS);
            const bag = this.left.items[SLOT_BAG];
            const info = bag && this.bagInfo(bag.name);
            return (info && info.rows) || this.catalog.baseRows || 2;
        },
        pouchCells() {
            const pouch = this.left.items[SLOT_POUCH];
            const info = pouch && this.bagInfo(pouch.name);
            return (info && info.cells) || 0;
        },
        isOpen(side, slot) {
            if (side === 'left') return Math.floor((slot - 1) / COLS) < this.openRows('left');
            return slot <= this.right.slots;
        },
        // grid cells of a side: the player's bag grid is 54, a container has its own slot count (Fence 126)
        // sale price of a stack while the Fence is open ($ label on the item)
        itemPrice(item) { return item.name === 'money' || !this.market || !this.market.values ? 0 : (this.market.values[item.name] || 0) * item.count; },
        gridSize(side) { return side === 'left' ? GRID : this.right.slots; },
        gridItems(inv) {
            const list = [], limit = inv === this.left ? GRID : inv.slots;
            for (const slot in inv.items) if (Number(slot) <= limit) list.push(inv.items[slot]);
            return list;
        },
        itemStyle(item, preview) {
            const [w, h] = this.sizeOf(item.name);
            const x = (item.slot - 1) % COLS, y = Math.floor((item.slot - 1) / COLS);
            const style = {
                left: x * CELL_REM + 'rem', top: y * CELL_REM + 'rem',
                width: `calc(${w * CELL_REM}rem - var(--gap))`, height: `calc(${h * CELL_REM}rem - var(--gap))`,
            };
            if (!preview && this.drag && this.drag.item === item) style.opacity = 0.35;
            return style;
        },

        // ---------- fit rules (same as the server) ----------
        overlaps(slotA, wA, hA, slotB, wB, hB) {
            const ax = (slotA - 1) % COLS, ay = Math.floor((slotA - 1) / COLS);
            const bx = (slotB - 1) % COLS, by = Math.floor((slotB - 1) / COLS);
            return ax < bx + wB && bx < ax + wA && ay < by + hB && by < ay + hA;
        },
        // Items in the way of `item` at `slot`. Moving inside one inventory ignores the item itself
        blockers(side, slot, item, ignoreSelf) {
            const inv = this.inv(side);
            const [w, h] = this.sizeOf(item.name);
            const list = [];
            for (const key in inv.items) {
                const other = inv.items[key];
                if (Number(key) > this.gridSize(side) || (ignoreSelf && other === item)) continue;
                const [ow, oh] = this.sizeOf(other.name);
                if (this.overlaps(slot, w, h, other.slot, ow, oh)) list.push(other);
            }
            return list;
        },
        gridFits(side, slot, item) {
            const [w, h] = this.sizeOf(item.name);
            const x = (slot - 1) % COLS, y = Math.floor((slot - 1) / COLS);
            if (x + w > COLS || y + h > this.openRows(side)) return false;
            const sameInv = this.drag ? this.drag.side === side : false;
            const blocking = this.blockers(side, slot, item, sameInv);
            if (blocking.length === 0) return true;
            // One item exactly at the target: stack onto it or swap with it (server decides the swap fit)
            if (blocking.length === 1 && blocking[0].slot === slot) return true;
            return false;
        },
        fixedFits(slot, item) {
            const data = this.items[item.name] || {};
            const bag = this.bagInfo(item.name);
            if (slot === SLOT_W1 || slot === SLOT_W2) return !!data.weapon;
            if (slot === SLOT_ARMOR) return !!(this.catalog.vests && this.catalog.vests[item.name]);
            if (slot === SLOT_BAG) return !!bag && bag.kind === 'back';
            if (slot === SLOT_POUCH) return !!bag && bag.kind === 'pouch';
            const [w, h] = this.sizeOf(item.name);
            return slot - POUCH_FIRST < this.pouchCells() && w === 1 && h === 1 && !bag;
        },
        // First grid slot where `item` fits in `side` (taken = extra { slot, w, h } cells already promised)
        findFit(side, item, taken) {
            const [w, h] = this.sizeOf(item.name);
            const inv = this.inv(side);
            const rows = this.openRows(side);
            for (let slot = 1; slot <= this.gridSize(side); slot++) {
                const x = (slot - 1) % COLS, y = Math.floor((slot - 1) / COLS);
                if (x + w > COLS || y + h > rows) continue;
                let free = true;
                for (const key in inv.items) {
                    const other = inv.items[key];
                    if (Number(key) > this.gridSize(side)) continue;
                    const [ow, oh] = this.sizeOf(other.name);
                    if (this.overlaps(slot, w, h, other.slot, ow, oh)) { free = false; break; }
                }
                for (const t of taken || []) if (free && this.overlaps(slot, w, h, t.slot, t.w, t.h)) free = false;
                if (free) return slot;
            }
            return null;
        },

        // ---------- cell look ----------
        cellClass(inv, side, slot) {
            const cls = {};
            if (!this.isOpen(side, slot)) cls.locked = true;
            const t = this.target;
            if (t && t.side === side && t.cells.has(slot)) cls[t.ok ? 'ok' : 'bad'] = true;
            return cls;
        },
        fixedClass(slot) {
            const cls = {};
            if (slot >= POUCH_FIRST && slot - POUCH_FIRST >= this.pouchCells()) cls.locked = true;
            const t = this.target;
            if (t && t.side === 'left' && t.slot === slot && slot > GRID) cls[t.ok ? 'ok' : 'bad'] = true;
            return cls;
        },
        hoverCell(side, slot) {
            this.hover = side ? { side, slot } : null;
        },

        // ---------- moving items ----------
        startDrag(e, side, item) {
            if (this.busy) return;
            if (e.ctrlKey) return this.quickTransfer(side, item);
            const rect = e.currentTarget.getBoundingClientRect();
            const cell = CELL_REM * remPx();
            const inGrid = item.slot <= this.gridSize(side);
            this.drag = {
                side, item,
                offsetX: inGrid ? e.clientX - rect.left : cell / 2,
                offsetY: inGrid ? e.clientY - rect.top : cell / 2,
                cellX: inGrid ? Math.floor((e.clientX - rect.left) / cell) : 0,
                cellY: inGrid ? Math.floor((e.clientY - rect.top) / cell) : 0,
            };
            this.mouse = { x: e.clientX, y: e.clientY };
            this.tip = null;
            this.$nextTick(() => moveGhost(e.clientX - this.drag.offsetX, e.clientY - this.drag.offsetY, true));
        },
        onMove(e) {
            this.mouse = { x: e.clientX, y: e.clientY };
            if (this.drag) moveGhost(e.clientX - this.drag.offsetX, e.clientY - this.drag.offsetY);
        },
        onUp(e) {
            if (!this.drag) return;
            const drag = this.drag, t = this.target;
            this.drag = null;
            // Dropped outside every panel: no ground drops, the player's own item can only be destroyed
            const outside = e && e.target && (e.target.classList.contains('inv') || e.target.classList.contains('layout'));
            if (outside && drag.side === 'left' && (!this.market || this.market.mode === 'fence')) return this.askDestroy(drag.item);
            if (this.hover && this.hover.side === 'plot' && drag.side === 'left') return this.plotInstall(this.hover.key, drag.item);
            if (this.hover && this.hover.side === 'desk' && drag.side === 'left' && drag.item.name === 'money') return this.deskAct('deposit', { invSlot: drag.item.slot });
            if (!t || !t.ok) return;
            if (t.side === drag.side && t.slot === drag.item.slot) return;
            this.move(drag.side, drag.item, t.side, t.slot);
        },
        // Moves locally at once, then asks the server; a refusal puts everything back
        // count < item.count moves part of a stack (split) into an empty cell
        async move(fromSide, item, toSide, toSlot, count) {
            const fromInv = this.inv(fromSide), toInv = this.inv(toSide);
            const before = { from: { ...fromInv.items }, to: { ...toInv.items } };
            const target = toInv.items[toSlot];
            const fromSlot = item.slot;
            count = count || item.count;

            // Cash: one slot holds at most MONEY_STACK (extras config); a merge moves only what fits
            if (target && target !== item && item.name === 'money' && target.name === 'money') {
                const room = MONEY_STACK - target.count;
                if (room <= 0) return false;
                count = Math.min(count, room);
                delete fromInv.items[fromSlot];
                if (count < item.count) fromInv.items[fromSlot] = { ...item, count: item.count - count };
                toInv.items[toSlot] = { ...target, count: target.count + count };
            } else {
            delete fromInv.items[fromSlot];
            if (count < item.count) {
                fromInv.items[fromSlot] = { ...item, count: item.count - count };
                toInv.items[toSlot] = { ...item, slot: toSlot, count };
            } else if (target && target.name === item.name && target !== item && this.items[item.name] && this.items[item.name].stack) {
                toInv.items[toSlot] = { ...target, count: target.count + item.count };
            } else {
                if (target && target !== item) fromInv.items[fromSlot] = { ...target, slot: fromSlot };
                toInv.items[toSlot] = { ...item, slot: toSlot };
            }
            }

            this.busy = true;
            const ok = await post('swapItems', {
                fromSlot, fromType: this.typeOf(fromSide),
                toSlot, toType: this.typeOf(toSide),
                count,
            });
            this.busy = false;

            if (!ok) {
                fromInv.items = before.from;
                if (toInv !== fromInv) toInv.items = before.to;
            } else {
                this.$nextTick(() => popItem(toSide + toSlot));
            }
            return ok;
        },
        // ---------- confirm / amount window ----------
        askDestroy(item) {
            this.modal = { kind: 'destroy', title: this.label(item), item };
            this.$nextTick(popModal);
        },
        askSplit(side, item) {
            if (this.busy || this.drag || item.count < 2 || !(this.items[item.name] && this.items[item.name].stack)) return;
            this.tip = null;
            this.modal = { kind: 'split', title: this.label(item), side, item, min: 1, max: item.count - 1, value: Math.floor(item.count / 2) };
            this.$nextTick(popModal);
        },
        modalCancel() { this.modal = null; },
        async modalOk() {
            const m = this.modal;
            if (!m || this.busy) return;
            this.modal = null;
            if (m.kind === 'destroy') {
                this.busy = true;
                await post('ataDestroy', m.item.slot);
                this.busy = false;
            } else if (m.kind === 'split') {
                const slot = this.findFit(m.side, m.item);
                if (slot) this.move(m.side, m.item, m.side, slot, m.value);
            } else if (m.kind === 'buy') {
                this.marketAct('buy', m.id, m.value);
            }
        },
        quickTransfer(side, item) {
            if (!this.container) return;
            const other = side === 'left' ? 'right' : 'left';
            const slot = this.findFit(other, item);
            if (slot) this.move(side, item, other, slot);
        },
        async takeAll() {
            if (!this.container || this.busy) return;
            const list = Object.values(this.right.items).sort((a, b) => a.slot - b.slot);
            for (const item of list) {
                const slot = this.findFit('left', item);
                if (slot) await this.move('right', item, 'left', slot);
            }
        },
        use(side, item) {
            if (this.market && this.market.mode === 'desk' && side === 'left' && item.name === 'money') return this.deskAct('deposit', { invSlot: item.slot });
            if (side === 'left') post('useItem', item.slot);
        },
        // ---------- RUN V Black Market / Suspicious Door ----------
        kfmt(n, item) { return item === 'money' && n >= 1000 ? Math.floor(n / 1000) + 'K' : String(n); },
        dealReady(d) { return !!d && d.inputs.every((i) => i.have >= i.count); },
        async marketAct(kind, id, count) {
            if (this.busy) return;
            this.busy = true;
            const resp = await post('marketAction', { kind, id, count });
            this.busy = false;
            if (resp && resp.data) this.market = resp.data;
        },
        offerClick(o) {
            // Stackable offers (ammo) ask how many first
            if (o.state === 'buy' && o.max) {
                const afford = Math.floor(this.market.cash / o.price);
                const max = Math.max(1, Math.min(o.max, afford));
                this.modal = { kind: 'buy', title: this.label({ name: o.item }), id: o.id, price: o.price, min: 1, max, value: max };
                return this.$nextTick(popModal);
            }
            if (o.state === 'buy') this.marketAct('buy', o.id);
            else if (o.state === 'unlock') this.marketAct('unlock', o.id);
        },
        async growAct(kind, index) {
            if (this.busy) return;
            this.busy = true;
            const resp = await post('marketAction', { target: 'grow', kind, index });
            this.busy = false;
            if (resp && resp.data) this.market = resp.data;
        },
        async tradeAct(kind) {
            if (this.busy) return;
            if (kind === 'fence' && this.fenceTotal <= 0) return;
            if (kind === 'smuggler' && this.market.cost <= 0) return;
            this.busy = true;
            const resp = await post('marketAction', { target: 'trade', kind });
            this.busy = false;
            if (resp && resp.data) this.market = resp.data;
        },
        async deskAct(kind, extra) {
            if (this.busy) return;
            this.busy = true;
            const resp = await post('marketAction', Object.assign({ target: 'desk', kind }, extra || {}));
            this.busy = false;
            if (resp && resp.data) {
                this.market = resp.data;
                this.deskTake = Math.min(this.deskTake, this.market.stored);
            }
        },
        hoverPlot(key) { this.hover = { side: 'plot', key }; },
        plotFilled(key) {
            if (key === 'main') return !!this.market.main;
            return !!(this.market.extra && this.market.extra[Number(key.slice(5)) - 1]);
        },
        plotClass(key) {
            if (!this.drag || !this.hover || this.hover.side !== 'plot' || this.hover.key !== key) return {};
            return this.plotFilled(key) ? { bad: true } : { ok: true };
        },
        async plotInstall(key, item) {
            if (this.plotFilled(key) || this.busy) return;
            this.busy = true;
            const resp = await post('marketAction', { kind: 'install', plot: this.market.plot, slot: key, invSlot: item.slot });
            this.busy = false;
            if (resp && resp.data) this.market = resp.data;
        },
        makeDeal() {
            const d = this.market.deals[this.dealSel];
            if (this.dealReady(d)) this.marketAct('deal', d.id);
        },
        close() {
            this.visible = false;
            this.modal = null;
            this.market = null;
            this.dealTip = null;
            this.drag = null;
            this.tip = null;
            post('exit');
        },

        // ---------- messages from Lua ----------
        refreshSlots(payload) {
            const list = Array.isArray(payload.items) ? payload.items : payload.items ? [payload.items] : [];
            for (const data of list) {
                if (!data || !data.item) continue;
                const toLeft = !data.inventory || data.inventory === 'player' || data.inventory == this.left.id;
                const inv = toLeft ? this.left : this.right;
                if (!inv) continue;
                if (data.item.name) inv.items[data.item.slot] = data.item;
                else delete inv.items[data.item.slot];
            }
        },
    },

    mounted() {
        window.addEventListener('message', (e) => {
            const { action, data } = e.data || {};
            if (action === 'init') {
                this.items = data.items || {};
                if (data.imagepath) this.imagepath = data.imagepath;
                if (data.leftInventory) this.left = { ...data.leftInventory, type: 'player', items: toSlotMap(data.leftInventory.items) };
            } else if (action === 'marketUpdate') {
                if (this.market && this.market.mode === data.mode) this.market = data;
            } else if (action === 'market') {
                if (data.mode === 'desk') { this.deskTab = 'storage'; this.deskTake = 0; }
                if (!this.market || this.market.mode !== data.mode) this.bmTab = 'GEAR';
                this.market = data;
                this.dealSel = 0;
            } else if (action === 'setupInventory') {
                this.market = null;
                if (data.leftInventory) this.left = { ...data.leftInventory, type: 'player', items: toSlotMap(data.leftInventory.items) };
                this.right = data.rightInventory ? { ...data.rightInventory, items: toSlotMap(data.rightInventory.items) } : null;
                this.visible = true;
            } else if (action === 'refreshSlots') {
                this.refreshSlots(data || {});
            } else if (action === 'closeInventory') {
                this.visible = false;
                this.modal = null;
                this.market = null;
                this.dealTip = null;
                this.drag = null;
                this.tip = null;
            } else if (action === 'setInventoryVisible') {
                this.visible = data !== false;
            } else if (action === 'ataItems') {
                this.items = { ...this.items, ...data };
            } else if (action === 'ataCatalog') {
                this.catalog = { tier: data.tier || {}, bags: data.bags || {}, baseRows: data.baseRows || 2, vests: data.vests || {} };
            }
        });

        window.addEventListener('keydown', (e) => {
            if (!this.visible) return;
            if (this.modal) {
                if (e.key === 'Escape') this.modalCancel();
                else if (e.key === 'e' || e.key === 'E') this.modalOk();
                return;
            }
            if (e.key === 'Escape') this.close();
            else if ((e.key === 'e' || e.key === 'E') && this.market && this.market.mode === 'smuggler') this.tradeAct('smuggler');
            else if ((e.key === 'e' || e.key === 'E') && this.container && !this.market) this.takeAll();
        });

        post('uiLoaded');
    },
}).mount('#app');
