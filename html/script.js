const ui = document.getElementById('boombox-ui');
const themeToggle = document.getElementById('themeToggle');
const trackStatus = document.getElementById('trackStatus');
const playPauseBtn = document.getElementById('playPauseBtn');
const stopBtn = document.getElementById('stopBtn');
const urlInput = document.getElementById('url');
const closeBtn = document.getElementById('closeBtn');

let isPlaying = false;
let isPaused = false;

// Met à jour le statut affiché
function updateStatus() {
    if (isPlaying && !isPaused) trackStatus.textContent = "▶ Playing";
    else if (isPlaying && isPaused) trackStatus.textContent = "⏸ Paused";
    else trackStatus.textContent = "";
}

// Play / Pause / Resume
playPauseBtn.addEventListener('click', () => {
    const url = urlInput.value.trim();
    if (!isPlaying && url) {
        isPlaying = true;
        isPaused = false;
        fetch(`https://${GetParentResourceName()}/playSound`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url })
        });
        playPauseBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
    } else if (isPlaying && !isPaused) {
        isPaused = true;
        fetch(`https://${GetParentResourceName()}/pauseSound`, { method: 'POST' });
        playPauseBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
    } else if (isPlaying && isPaused) {
        isPaused = false;
        fetch(`https://${GetParentResourceName()}/resumeSound`, { method: 'POST' });
        playPauseBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
    }
    updateStatus();
});

// Stop
stopBtn.addEventListener('click', () => {
    isPlaying = false;
    isPaused = false;
    fetch(`https://${GetParentResourceName()}/stopSound`, { method: 'POST' });
    playPauseBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
    updateStatus();
});

// Volume
document.getElementById('volume').addEventListener('input', e => {
    fetch(`https://${GetParentResourceName()}/setVolume`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ volume: parseFloat(e.target.value) })
    });
});

// Distance slider
const distanceSlider = document.getElementById('distance');
const distanceValue = document.getElementById('distanceValue');

distanceSlider.addEventListener('input', (e) => {
    const dist = parseInt(e.target.value);
    distanceValue.textContent = dist + "m";

    fetch(`https://${GetParentResourceName()}/setDistance`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ distance: dist })
    });
});

// Close UI
closeBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
    ui.classList.add('hidden');
});

// Toggle theme with smooth transition
themeToggle.addEventListener('click', () => {
    if (ui.classList.contains('dark')) {
        ui.classList.remove('dark');
        ui.classList.add('light');
    } else {
        ui.classList.remove('light');
        ui.classList.add('dark');
    }
});

// Listen to NUI messages to show/hide UI
window.addEventListener('message', (event) => {
    if (event.data.type === 'showUI') {
        if (event.data.display) ui.classList.remove('hidden');
        else ui.classList.add('hidden');
    }
});

// Initial status update
updateStatus();


const boomboxUI = document.getElementById('boombox-ui');
const dragBar = document.getElementById('drag-bar');

let isDragging = false;
let dragOffsetX = 0;
let dragOffsetY = 0;

dragBar.addEventListener('mousedown', (e) => {
    isDragging = true;
    // Calculer le décalage entre la souris et le coin supérieur gauche de la fenêtre
    const rect = boomboxUI.getBoundingClientRect();
    dragOffsetX = e.clientX - rect.left;
    dragOffsetY = e.clientY - rect.top;

    // Pour éviter la sélection de texte lors du drag
    document.body.style.userSelect = 'none';
});

document.addEventListener('mouseup', () => {
    isDragging = false;
    document.body.style.userSelect = 'auto';
});

document.addEventListener('mousemove', (e) => {
    if (isDragging) {
        // Calculer la nouvelle position
        let left = e.clientX - dragOffsetX;
        let top = e.clientY - dragOffsetY;

        // Limites pour rester visible dans la fenêtre (optionnel)
        const windowWidth = window.innerWidth;
        const windowHeight = window.innerHeight;
        const elemWidth = boomboxUI.offsetWidth;
        const elemHeight = boomboxUI.offsetHeight;

        left = Math.min(Math.max(0, left), windowWidth - elemWidth);
        top = Math.min(Math.max(0, top), windowHeight - elemHeight);

        // Appliquer la position en px
        boomboxUI.style.position = 'fixed';
        boomboxUI.style.left = left + 'px';
        boomboxUI.style.top = top + 'px';
    }
});
