const ui = document.getElementById('boombox-ui');
const themeToggle = document.getElementById('themeToggle');
const trackStatus = document.getElementById('trackStatus');
const playPauseBtn = document.getElementById('playPauseBtn');
const prevTrackBtn = document.getElementById('prevTrackBtn');
const nextTrackBtn = document.getElementById('nextTrackBtn');
const urlInput = document.getElementById('url');
const closeBtn = document.getElementById('closeBtn');
const addToPlaylistBtn = document.getElementById('addToPlaylistBtn');
const createPlaylistBtn = document.getElementById('createPlaylistBtn');
const playlistNameInput = document.getElementById('playlistName');
const playlistsMenu = document.getElementById('playlistsMenu');  
const playlistTracks = document.getElementById('playlistTracks');
const currentPlaylistTitle = document.getElementById('currentPlaylistTitle');
const playlistSection = document.getElementById('playlist-section');
const deletePlaylistBtn = document.getElementById('deletePlaylistBtn');

let currentTrackTitle = "";
let isPlaying = false;
let isPaused = false;

let currentTrackIndex = 0; 
let playlistPlaying = false; 

let playlists = {}; 
let currentPlaylist = null;

function savePlaylists() {
    localStorage.setItem('boomboxPlaylists', JSON.stringify(playlists));
}

function loadPlaylists() {
    const saved = localStorage.getItem('boomboxPlaylists');
    if (saved) {
        playlists = JSON.parse(saved);
        currentPlaylist = Object.keys(playlists)[0] || null;
        if (currentPlaylist) {
            currentPlaylistTitle.textContent = currentPlaylist;
        }
        renderPlaylists();
    }
    deletePlaylistBtn.disabled = !currentPlaylist;
}

loadPlaylists();

function updateStatus() {
    if (isPlaying && !isPaused) {
        let title = '';

        if (playlistPlaying && currentPlaylist && playlists[currentPlaylist] && playlists[currentPlaylist][currentTrackIndex]) {
            title = playlists[currentPlaylist][currentTrackIndex].title;
        } else if (!playlistPlaying) {
            title = currentTrackTitle || "";
        }

        if (title) {
            trackStatus.textContent = `▶ Playing: ${title}`;
        } else {
            trackStatus.textContent = "▶ Playing";
        }
    } else if (isPlaying && isPaused) {
        trackStatus.textContent = "⏸ Paused";
    } else {
        trackStatus.textContent = "";
    }
}

function playSimpleLink() {
    const url = urlInput.value.trim();
    if (!url) return;

    isPlaying = true;
    isPaused = false;
    playlistPlaying = false;

    currentTrackTitle = url;

    fetchVideoTitle(url).then(title => {
        currentTrackTitle = title;
        updateStatus();
    });

    fetch(`https://${GetParentResourceName()}/playSound`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url })
    });

    playPauseBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
    updateStatus();
}

playPauseBtn.addEventListener('click', () => {
    if (!isPlaying) {
        if (!playlistSection.classList.contains('hidden')) {
            // Playlist visible -> joue la playlist complète
            if (currentPlaylist && playlists[currentPlaylist] && playlists[currentPlaylist].length > 0) {
                playPlaylist();
            } else {
                playSimpleLink();
            }
        } else {
            // Playlist cachée -> joue lien simple uniquement
            playSimpleLink();
        }
    } else if (isPlaying && !isPaused) {
        isPaused = true;
        fetch(`https://${GetParentResourceName()}/pauseSound`, { method: 'POST' });
        playPauseBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
        updateStatus();
    } else if (isPlaying && isPaused) {
        isPaused = false;
        fetch(`https://${GetParentResourceName()}/resumeSound`, { method: 'POST' });
        playPauseBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
        updateStatus();
    }
});

// Bouton précédent
prevTrackBtn.addEventListener('click', () => {
    if (!currentPlaylist || !playlists[currentPlaylist] || playlists[currentPlaylist].length === 0) return;

    currentTrackIndex = (currentTrackIndex > 0)
        ? currentTrackIndex - 1
        : playlists[currentPlaylist].length - 1;

    playFromPlaylist(currentPlaylist, currentTrackIndex);
});

// Bouton suivant
nextTrackBtn.addEventListener('click', () => {
    if (!currentPlaylist || !playlists[currentPlaylist] || playlists[currentPlaylist].length === 0) return;

    currentTrackIndex = (currentTrackIndex < playlists[currentPlaylist].length - 1)
        ? currentTrackIndex + 1
        : 0;

    playFromPlaylist(currentPlaylist, currentTrackIndex);
});

document.getElementById('volume').addEventListener('input', e => {
    fetch(`https://${GetParentResourceName()}/setVolume`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ volume: parseFloat(e.target.value) })
    });
});

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

closeBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
    ui.classList.add('hidden');
});

themeToggle.addEventListener('click', () => {
    ui.classList.toggle('dark');
    ui.classList.toggle('light');
});

window.addEventListener('message', (event) => {
    if (event.data.type === 'showUI') {
        if (event.data.display) ui.classList.remove('hidden');
        else ui.classList.add('hidden');
    }
});
updateStatus();

const boomboxUI = document.getElementById('boombox-ui');
const dragBar = document.getElementById('drag-bar');
let isDragging = false, dragOffsetX = 0, dragOffsetY = 0;

dragBar.addEventListener('mousedown', (e) => {
    isDragging = true;
    const rect = boomboxUI.getBoundingClientRect();
    dragOffsetX = e.clientX - rect.left;
    dragOffsetY = e.clientY - rect.top;
    document.body.style.userSelect = 'none';
});

document.addEventListener('mouseup', () => {
    isDragging = false;
    document.body.style.userSelect = 'auto';
});

document.addEventListener('mousemove', (e) => {
    if (isDragging) {
        let left = e.clientX - dragOffsetX;
        let top = e.clientY - dragOffsetY;

        const windowWidth = window.innerWidth;
        const windowHeight = window.innerHeight;
        const elemWidth = boomboxUI.offsetWidth;
        const elemHeight = boomboxUI.offsetHeight;

        left = Math.min(Math.max(0, left), windowWidth - elemWidth);
        top = Math.min(Math.max(0, top), windowHeight - elemHeight);

        boomboxUI.style.position = 'fixed';
        boomboxUI.style.left = left + 'px';
        boomboxUI.style.top = top + 'px';
    }
});

playlistNameInput.addEventListener('input', () => {
    if (playlistNameInput.value.length > 15) {
        playlistNameInput.value = playlistNameInput.value.slice(0, 15);
    }
});

createPlaylistBtn.addEventListener('click', () => {
    let name = playlistNameInput.value.trim();

    if (!name || playlists[name]) return;

    if (name.length > 15) {
        name = name.substring(0, 15);
    }

    playlists[name] = [];
    currentPlaylist = name;
    currentPlaylistTitle.textContent = name;
    playlistNameInput.value = "";
    renderPlaylists();
    savePlaylists();

    deletePlaylistBtn.disabled = false;
});

function selectPlaylist(name) {
    currentPlaylist = name;
    currentPlaylistTitle.textContent = name;
    renderPlaylists();
    deletePlaylistBtn.disabled = false;
}

function removeTrack(playlistName, index) {
    playlists[playlistName].splice(index, 1);
    renderPlaylists();
    savePlaylists();
}

function playFromPlaylist(playlistName, index) {
    const track = playlists[playlistName][index];
    if (!track) return;

    currentTrackIndex = index;
    playlistPlaying = true;
    isPlaying = true;
    isPaused = false;
    currentTrackTitle = track.title;

    fetch(`https://${GetParentResourceName()}/playSound`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: track.url })
    });

    playPauseBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
    updateStatus();
}

async function playPlaylist() {
    if (!currentPlaylist || playlists[currentPlaylist].length === 0) return;

    playlistPlaying = true;
    currentTrackIndex = 0;

    async function playNext() {
        if (!playlistPlaying || currentTrackIndex >= playlists[currentPlaylist].length) {
            playlistPlaying = false;
            isPlaying = false;
            isPaused = false;
            currentTrackTitle = "";
            playPauseBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
            updateStatus();
            return;
        }

        const track = playlists[currentPlaylist][currentTrackIndex];
        isPlaying = true;
        isPaused = false;
        currentTrackTitle = track.title;

        playPauseBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
        updateStatus();

        await fetch(`https://${GetParentResourceName()}/playSound`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url: track.url })
        });

        // Simule la lecture (3 minutes)
        setTimeout(() => {
            if (playlistPlaying) {
                currentTrackIndex++;
                playNext();
            }
        }, 180000); 
    }

    playNext();
}

function renderPlaylists() {
    playlistsMenu.innerHTML = "";
    const playlistNames = Object.keys(playlists);

    if (playlistNames.length === 0) {
        const li = document.createElement('li');
        li.textContent = "No playlists available";
        li.style.fontStyle = 'italic';
        li.style.color = '#777';
        playlistsMenu.appendChild(li);

        currentPlaylistTitle.textContent = "No playlist selected";
        deletePlaylistBtn.disabled = true;
        playlistTracks.innerHTML = "";
        return;
    }

    for (let name in playlists) {
        const li = document.createElement('li');
        li.textContent = name;
        if (name === currentPlaylist) li.classList.add('active');
        li.addEventListener('click', () => selectPlaylist(name));
        playlistsMenu.appendChild(li);
    }

    playlistTracks.innerHTML = "";
    if (!currentPlaylist) return;

    playlists[currentPlaylist].forEach((track, index) => {
        const li = document.createElement('li');
        li.innerHTML = `
            <span>${track.title}</span>
            <button class="removeTrack"><i class="fa-solid fa-trash"></i></button>
        `;

        li.querySelector('span').addEventListener('click', () => playFromPlaylist(currentPlaylist, index));
        li.querySelector('.removeTrack').addEventListener('click', () => removeTrack(currentPlaylist, index));

        playlistTracks.appendChild(li);
    });
}


async function fetchVideoTitle(url) {
    if (url.includes('youtube.com') || url.includes('youtu.be')) {
        try {
            const res = await fetch(`https://www.youtube.com/oembed?url=${url}&format=json`);
            const data = await res.json();
            return data.title;
        } catch (e) {
            return url;
        }
    }
    return url.split('/').pop();
}

const playlistDropdown = document.createElement('ul');
playlistDropdown.id = 'playlistDropdown';
playlistDropdown.classList.add('hidden');
playlistDropdown.style.position = 'absolute';
playlistDropdown.style.top = '110%';
playlistDropdown.style.left = '0';
playlistDropdown.style.background = '#181818';
playlistDropdown.style.borderRadius = '8px';
playlistDropdown.style.listStyle = 'none';
playlistDropdown.style.padding = '5px 0';
playlistDropdown.style.margin = '0';
playlistDropdown.style.minWidth = '160px';
playlistDropdown.style.boxShadow = '0 5px 15px rgba(0,0,0,0.3)';
playlistDropdown.style.zIndex = '100';

addToPlaylistBtn.parentElement.style.position = 'relative';
addToPlaylistBtn.parentElement.appendChild(playlistDropdown);

let playlistAddUrl = "";

addToPlaylistBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    playlistAddUrl = urlInput.value.trim();
    if (!playlistAddUrl) return;
    renderPlaylistDropdown();
    playlistDropdown.classList.toggle('hidden');
});

function renderPlaylistDropdown() {
    playlistDropdown.innerHTML = "";
    if (Object.keys(playlists).length === 0) {
        const li = document.createElement('li');
        li.textContent = "No playlists available";
        li.style.color = "#777";
        li.style.padding = "8px 12px";
        playlistDropdown.appendChild(li);
        return;
    }
    for (let name in playlists) {
        const li = document.createElement('li');
        li.textContent = name;
        li.style.padding = "8px 12px";
        li.style.cursor = "pointer";
        li.style.color = "white";
        li.addEventListener('click', async () => {
            const title = await fetchVideoTitle(playlistAddUrl);
            playlists[name].push({ title, url: playlistAddUrl });
            currentPlaylist = name;
            currentPlaylistTitle.textContent = name;
            playlistDropdown.classList.add('hidden');
            renderPlaylists();
            urlInput.value = "";
            savePlaylists();
            deletePlaylistBtn.disabled = false;
        });
        li.addEventListener('mouseenter', () => li.style.backgroundColor = '#1db954');
        li.addEventListener('mouseleave', () => li.style.backgroundColor = 'transparent');
        playlistDropdown.appendChild(li);
    }
}

document.addEventListener('click', () => {
    if (!playlistDropdown.classList.contains('hidden')) {
        playlistDropdown.classList.add('hidden');
    }
});

window.addEventListener('DOMContentLoaded', () => {
    playlistDropdown.classList.add('hidden');
});

const expandBtn = document.getElementById('expandBtn');
let isExpanded = false;

expandBtn.addEventListener('click', () => {
    isExpanded = !isExpanded;

    if (isExpanded) {
        ui.classList.add('expanded');
        playlistSection.classList.remove('hidden');
        expandBtn.innerHTML = '<i class="fa-solid fa-down-left-and-up-right-to-center"></i>';
    } else {
        ui.classList.remove('expanded');
        playlistSection.classList.add('hidden');
        expandBtn.innerHTML = '<i class="fa-solid fa-up-right-and-down-left-from-center"></i>';
    }
});

const deleteConfirmContainer = document.getElementById('deleteConfirmContainer');
const confirmDeleteBtn = document.getElementById('confirmDeleteBtn');
const cancelDeleteBtn = document.getElementById('cancelDeleteBtn');

// Quand on clique sur la corbeille
deletePlaylistBtn.addEventListener('click', () => {
    if (!currentPlaylist) return;
    // Affiche le modal avec la classe
    deleteConfirmContainer.classList.remove('hidden');
});

cancelDeleteBtn.addEventListener('click', () => {
    deleteConfirmContainer.classList.add('hidden'); 
});

confirmDeleteBtn.addEventListener('click', () => {
    if (!currentPlaylist) return;

    delete playlists[currentPlaylist];

    const playlistNames = Object.keys(playlists);
    if (playlistNames.length > 0) {
        currentPlaylist = playlistNames[0];
        currentPlaylistTitle.textContent = currentPlaylist;
        deletePlaylistBtn.disabled = false;
    } else {
        currentPlaylist = null;
        currentPlaylistTitle.textContent = "No playlist selected";
        deletePlaylistBtn.disabled = true;
        playlistSection.classList.remove('hidden');
    }

    renderPlaylists();
    savePlaylists();
    deleteConfirmContainer.classList.add('hidden');
});
