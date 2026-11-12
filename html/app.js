(() => {
    const root = document.getElementById('hud-root');

    const RING_CIRC = 2 * Math.PI * 16; // r = 16 -> ~100.53
    const ARC_MAX = 198; // 270 deg de r = 42

    let currentStyle = 'minimal';
    let maxSpeed = 240;
    let speedUnit = 'KM/H';
    let voiceLabels = { 1: 'Susurro', 2: 'Normal', 3: 'Grito' };

    const barEls = {
        hp: document.querySelectorAll('[data-bar="hp"]'),
        armor: document.querySelectorAll('[data-bar="armor"]'),
        food: document.querySelectorAll('[data-bar="food"]'),
        stamina: document.querySelectorAll('[data-bar="stamina"]'),
        oxygen: document.querySelectorAll('[data-bar="oxygen"]')
    };

    const ringEls = {
        hp: document.querySelectorAll('[data-ring="hp"]'),
        armor: document.querySelectorAll('[data-ring="armor"]'),
        food: document.querySelectorAll('[data-ring="food"]'),
        stamina: document.querySelectorAll('[data-ring="stamina"]'),
        oxygen: document.querySelectorAll('[data-ring="oxygen"]'),
        voice: document.querySelectorAll('[data-ring="voice"]')
    };

    const txtEls = {
        food: document.querySelectorAll('[data-txt="food"]'),
        stamina: document.querySelectorAll('[data-txt="stamina"]'),
        oxygen: document.querySelectorAll('[data-txt="oxygen"]')
    };

    const voiceCircleEls = document.querySelectorAll('[data-voice-circle]');
    const voiceBarsWrapEls = document.querySelectorAll('[data-voice-bars]');
    const voiceRingEls = document.querySelectorAll('[data-voice-ring]');
    const voiceDotEls = document.querySelectorAll('[data-voice-dot]');
    const voiceLabelEls = document.querySelectorAll('[data-voice-label]');

    const speedNumEls = document.querySelectorAll('[data-speed-num]');
    const speedUnitEls = document.querySelectorAll('[data-speed-unit]');
    const speedBarEls = document.querySelectorAll('[data-speed-bar]');
    const speedArcEls = document.querySelectorAll('[data-speed-arc]');
    const gearEls = document.querySelectorAll('[data-gear]');
    const gearPrefixEls = document.querySelectorAll('[data-gear-prefix]');

    function clampPct(v) {
        const num = Number(v) || 0;
        return Math.max(0, Math.min(100, num));
    }

    function applyStyle(styleName) {
        const valid = ['minimal', 'rings', 'tactical'];
        currentStyle = valid.includes(styleName) ? styleName : 'minimal';
        root.classList.remove('style-minimal', 'style-rings', 'style-tactical');
        root.classList.add(`style-${currentStyle}`);
    }

    function updateMetric(key, val) {
        const pct = clampPct(val);

        if (barEls[key]) {
            barEls[key].forEach((el) => {
                el.style.width = `${pct}%`;
            });
        }

        if (ringEls[key]) {
            const offset = RING_CIRC * (1 - pct / 100);
            ringEls[key].forEach((el) => {
                el.style.strokeDashoffset = offset.toFixed(2);
            });
        }

        if (txtEls[key]) {
            txtEls[key].forEach((el) => {
                el.textContent = `${Math.round(pct)}%`;
            });
        }
    }

    function updateVoice(talking, mode) {
        const lvl = Math.max(1, Math.min(3, Number(mode) || 2));
        const voicePct = (lvl / 3) * 100;
        const voiceOffset = RING_CIRC * (1 - voicePct / 100);
        const label = voiceLabels[lvl] || 'Normal';

        voiceCircleEls.forEach((el) => {
            el.classList.toggle('is-talking', Boolean(talking));
        });

        voiceRingEls.forEach((el) => {
            el.classList.toggle('is-talking', Boolean(talking));
        });

        if (ringEls.voice) {
            ringEls.voice.forEach((el) => {
                el.style.strokeDashoffset = voiceOffset.toFixed(2);
            });
        }

        voiceBarsWrapEls.forEach((wrap) => {
            const bars = wrap.querySelectorAll('.vb');
            bars.forEach((b, idx) => {
                b.classList.toggle('active', idx < lvl);
            });
        });

        voiceDotEls.forEach((el) => {
            el.style.opacity = talking ? '1' : '0.45';
        });

        voiceLabelEls.forEach((el) => {
            el.textContent = label;
            el.style.opacity = talking ? '1' : '0.65';
        });
    }

    function updateVehicle(show, speed, gear) {
        root.classList.toggle('no-speedo', !show);

        const spd = Math.max(0, Math.round(Number(speed) || 0));
        const pct = Math.min(spd / Math.max(maxSpeed, 1), 1);

        speedNumEls.forEach((el) => {
            el.textContent = String(spd);
        });

        speedBarEls.forEach((el) => {
            el.style.width = `${(pct * 100).toFixed(1)}%`;
        });

        speedArcEls.forEach((el) => {
            const offset = ARC_MAX * (1 - pct);
            el.style.strokeDashoffset = offset.toFixed(2);
        });

        const gearText = gear ? String(gear) : 'N';
        gearEls.forEach((el) => {
            el.textContent = gearText;
        });
        gearPrefixEls.forEach((el) => {
            el.textContent = `M ${gearText}`;
        });
    }

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.type) return;

        switch (data.type) {
            case 'visibility': {
                const visible = Boolean(data.visible);
                root.classList.toggle('is-hidden', !visible);
                root.setAttribute('aria-hidden', String(!visible));
                break;
            }
            case 'config': {
                if (data.style) {
                    applyStyle(data.style);
                }
                if (data.maxSpeed) {
                    maxSpeed = Number(data.maxSpeed) || 240;
                }
                if (data.speedUnit) {
                    speedUnit = String(data.speedUnit);
                    speedUnitEls.forEach((el) => {
                        el.textContent = speedUnit;
                    });
                }
                if (data.voiceLabels && typeof data.voiceLabels === 'object') {
                    voiceLabels = data.voiceLabels;
                }
                break;
            }
            case 'status': {
                updateMetric('hp', data.hp);
                updateMetric('armor', data.armor);
                updateMetric('food', data.food);
                updateMetric('stamina', data.stamina);
                updateMetric('oxygen', data.oxygen);
                updateVoice(data.talking, data.voiceMode);
                break;
            }
            case 'vehicle': {
                updateVehicle(Boolean(data.show), data.speed, data.gear);
                break;
            }
        }
    });

    root.classList.add('no-speedo');

    if (typeof GetParentResourceName === 'function') {
        fetch(`https://${GetParentResourceName()}/ready`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({})
        }).catch(() => {});
    } else {
        // Vista previa automatica al abrir la NUI fuera de FiveM (navegador)
        const params = new URLSearchParams(window.location.search);
        const initialStyle = params.get('style') || 'minimal';
        const hideBar = params.get('nobar') === '1';

        document.body.style.background = 'linear-gradient(135deg, #3b4a5a 0%, #1c242b 100%)';
        root.classList.remove('is-hidden');
        root.setAttribute('aria-hidden', 'false');

        applyStyle(initialStyle);
        updateMetric('hp', 85);
        updateMetric('armor', 60);
        updateMetric('food', 74);
        updateMetric('stamina', 92);
        updateMetric('oxygen', 100);
        updateVoice(true, 2);
        updateVehicle(true, 136, '4');

        if (!hideBar) {
            const bar = document.createElement('div');
            bar.style.cssText = [
                'position:fixed',
                'top:16px',
                'left:50%',
                'transform:translateX(-50%)',
                'display:flex',
                'gap:8px',
                'padding:6px 10px',
                'border-radius:10px',
                'background:rgba(8,8,10,0.75)',
                'border:1px solid rgba(255,255,255,0.18)',
                'box-shadow:0 10px 28px rgba(0,0,0,0.85)',
                'pointer-events:auto',
                'z-index:9999'
            ].join(';');

            [
                ['minimal', 'Estilo 1: Minimal'],
                ['rings', 'Estilo 2: Rings'],
                ['tactical', 'Estilo 3: Tactical']
            ].forEach(([styleKey, label]) => {
                const btn = document.createElement('button');
                btn.type = 'button';
                btn.textContent = label;
                btn.style.cssText = [
                    'cursor:pointer',
                    'padding:5px 10px',
                    'border-radius:6px',
                    'border:1px solid rgba(255,255,255,0.2)',
                    'background:rgba(255,255,255,0.1)',
                    'color:#fff',
                    'font-size:12px',
                    'font-weight:600'
                ].join(';');
                btn.addEventListener('click', () => applyStyle(styleKey));
                bar.appendChild(btn);
            });

            document.body.appendChild(bar);
        }
    }
})();
