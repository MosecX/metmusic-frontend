/* MetMusic · boceto — render con metadatos reales del backend (sin stream). */

const API = "https://tdl-qbz-api.metmusic.qzz.io";
const TOKEN =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtZXRtdXNpYy1hZG1pbi10b2tlbiIsIm5hbWUiOiJUT0tFTiIsInJvbGUiOiJhZG1pbiIsImFwcCI6Im1ldG11c2ljLWFuZHJvaWQiLCJ2ZXJzaW9uIjoiMS4wLjAiLCJwZXJtaXNzaW9ucyI6WyJzdHJlYW0iLCJzZWFyY2giLCJtZXRhZGF0YSIsInBsYXlsaXN0cyIsImhpc3RvcnkiLCJmYXZvcml0ZXMiLCJseXJpY3MiLCJjYW52YXMiLCJleHBsb3JlIl0sImRldmljZV9pZCI6ImEzZjhjMmQxZTViNzA5NDRmNmIyYThkOWMxZTNmNWE3YjlkMGUyZjRhNjhiMGMyZDRlNmY4YTBiMmM0ZDZlOGYwIiwic2Vzc2lvbl9pZCI6IjFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzIiwiaXNzdWVkX2J5IjoibWV0bXVzaWMtYmFja2VuZCIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJ0aWVyIjoiaGlyZXMiLCJtYXhfcXVhbGl0eSI6IkhJX1JFUyIsInByb3ZpZGVycyI6WyJxb2J1eiIsInRpZGFsIl0sImZlYXR1cmVzIjpbInN0cmVhbWluZyIsIm9mZmxpbmUiLCJseXJpY3Nfc3luYyIsImNhbnZhcyIsImVxdWFsaXplciIsInNjcm9iYmxpbmciXSwiaWF0IjoxNzUwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTksIm5iZiI6MTc1MDAwMDAwMCwianRpIjoiNGY1YTZiN2M4ZDllMGYxZjJhM2I0YzVkNmU3ZjgwOTFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjAiLCJhdWQiOiJ0ZGwtcWJ6LWFwaS5tZXRtdXNpYy5xenouaW8iLCJpc3MiOiJtZXRtdXNpYy1hdXRoIiwiZXh0cmFfZGF0YSI6eyJyZWdpb24iOiJMQVRBTSIsImxhbmd1YWdlIjoiZXMiLCJ0aGVtZSI6ImRhcmsiLCJhdWRpb19jb2RlY19wcmVmZXJlbmNlIjpbImZsYWMiLCJtcDQiLCJvcHVzIl0sIm1heF9iaXRyYXRlIjo5MjE2LCJzYW1wbGVfcmF0ZXMiOls0NDEwMCw0ODAwMCw5NjAwMCwxOTIwMDBdLCJiaXRfZGVwdGhzIjpbMTYsMjQsMzJdLCJjYW52YXNfZW5hYmxlZCI6dHJ1ZSwic2VnbWVudF9wcm94eSI6ZmFsc2UsImNhY2hlX3R0bCI6MzYwMCwic2Vzc2lvbl90b2tlbiI6ImUxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzYTRiNWM2ZDdlOGY5YTBiMWMyZDNlNGY1YTZiNyIsInJlZnJlc2hfdG9rZW4iOiIxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzEiLCJhcGlfa2V5X2ludGVybmFsIjoiYTliOGM3ZDZlNWY0YTNiMmMxZDBlOWY4YTdiNmM1ZDRlM2YyYTFiMGM5ZDhlN2Y2YTViNGMzZDJlMWYwIn19.9rMELXs3SAFkQ6960Reln8keTY9fo9YgK5JcL7I1Kzw";

const MET = window.MET || {
  moods: [null],
  home: { newReleases: [], charts: [], editorial: [], trending: [] },
  history: [],
  favs: [],
  health: { version: "—", services: [] },
  albums: {},
  playlists: {},
  corpus: [],
};

const TRACKS = new Map();
const CANVAS = { ...(MET.canvas || {}) };
const phone = document.getElementById("phone");
const screens = document.querySelectorAll(".screen");
const jumpBtns = document.querySelectorAll(".jump button");
let currentScreenId = "s-home";
let backScreen = "s-home";
let nowPlaying = null;
let isPlaying = true;
let currentDetail = null;
let live = false;
let searchType = "all";
let searchToken = 0;
let canvasToken = 0;
let searchDebounce = null;

/* ------------------------------------------------------------ helpers */

const $ = (s) => document.querySelector(s);
const esc = (s) =>
  String(s ?? "").replace(/[&<>"]/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
  })[c]);

function fmtDur(sec) {
  if (!sec && sec !== 0) return "";
  const m = Math.floor(sec / 60);
  const s = String(sec % 60).padStart(2, "0");
  return `${m}:${s}`;
}

function thumb(item, i = 1) {
  const t = item && item.t;
  if (!t) return null;
  return t[i] || t[1] || t[0] || null;
}

function urlStyle(url) {
  return url ? `style="background-image:url('${url}')"` : "";
}

function register(tracks) {
  (tracks || []).forEach((t) => {
    if (t && t.id != null) TRACKS.set(String(t.id), t);
  });
}

async function api(path, { auth = true, timeout = 9000 } = {}) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeout);
  try {
    const r = await fetch(API + path, {
      signal: ctrl.signal,
      headers: auth ? { Authorization: "Bearer " + TOKEN } : undefined,
    });
    if (!r.ok) throw new Error("HTTP " + r.status);
    return await r.json();
  } finally {
    clearTimeout(timer);
  }
}

/* ----------------------------------------------------- normalizadores */

function urlAt(thumbs, size) {
  if (!thumbs || !thumbs.length) return null;
  const exact = thumbs.find((t) => t.size === `${size}x${size}`);
  if (exact) return exact.url;
  const ge = thumbs.filter((t) => (t.width || 0) >= size);
  if (ge.length) return ge.sort((a, b) => a.width - b.width)[0].url;
  return thumbs.slice().sort((a, b) => a.width - b.width).pop().url;
}

function thumbs3(thumbs) {
  if (!thumbs || !thumbs.length) return [null, null, null];
  return [160, 640, 1280].map((s) => urlAt(thumbs, s));
}

function normTrack(t) {
  if (!t) return null;
  let thumbs = t.thumbnails;
  if (!thumbs && typeof t.thumbnail === "string") {
    thumbs = [{ url: t.thumbnail, width: 320, size: "320x320" }];
  }
  return {
    id: t.track_id,
    title: t.title,
    artist: t.artist,
    artistId: t.artist_id,
    album: t.album,
    albumId: t.album_id,
    dur: t.duration_seconds,
    x: t.explicit ? 1 : 0,
    t: thumbs3(thumbs),
  };
}

function normAlbum(a) {
  return {
    id: a.album_id,
    title: a.title,
    artist: a.artist,
    artistId: a.artist_id,
    release: a.release_date,
    n: a.number_of_tracks,
    dur: a.duration_seconds,
    x: a.explicit ? 1 : 0,
    t: thumbs3(a.thumbnails),
  };
}

function normPlaylist(p) {
  return {
    id: p.playlist_id,
    title: p.title,
    creator: p.creator,
    desc: p.description,
    n: p.number_of_tracks,
    dur: p.duration_seconds,
    t: thumbs3(p.thumbnails),
  };
}

function normAlbumDetail(raw) {
  const al = raw.album && typeof raw.album === "object" ? raw.album : raw;
  const base = normAlbum(al);
  base.genre = al.genre;
  base.label = al.label;
  base.tracks = (al.tracks || [])
    .map((t, i) => {
      const n = normTrack(t);
      if (n) {
        n.no = i + 1;
        if (!n.t.some(Boolean)) n.t = base.t;
      }
      return n;
    })
    .filter(Boolean)
    .slice(0, 40);
  base.n = base.n || base.tracks.length;
  return base;
}

function normPlaylistDetail(raw) {
  const base = normPlaylist(raw);
  base.tracks = (raw.tracks || [])
    .map((t, i) => {
      const n = normTrack(t);
      if (n) n.no = i + 1;
      return n;
    })
    .filter(Boolean)
    .slice(0, 40);
  base.n = base.n || base.tracks.length;
  base.release = raw.created;
  return base;
}

function normalizeHome(raw) {
  const sec = (id) =>
    (raw.sections || []).find((s) => s.id === id) || { items: [] };
  return {
    newReleases: sec("new_releases").items.map(normAlbum).filter((a) => a.id),
    charts: sec("charts_tracks").items.map(normTrack).filter((t) => t && t.id),
    editorial: sec("editorial_playlists").items
      .map(normPlaylist)
      .filter((p) => p.id),
    trending: sec("trending_artists").items.map((a) => ({
      id: a.artist_id,
      name: a.name,
      pic: a.picture,
    })),
  };
}

function normalizeHistory(list) {
  return (list || [])
    .map((item) => {
      const tr = normTrack(
        item && item.track && typeof item.track === "object" ? item.track : item
      );
      if (tr) tr.playedAt = (item.played_at || "").slice(5, 16).replace("T", " ");
      return tr;
    })
    .filter((t) => t && t.id);
}

function normalizeFavs(list) {
  return (list || [])
    .map((item) => {
      const tr = normTrack(
        item && item.track && typeof item.track === "object" ? item.track : item
      );
      if (tr) tr.addedAt = (item.added_at || "").slice(0, 10);
      return tr;
    })
    .filter((t) => t && t.id);
}

/* -------------------------------------------------------- navegación */

function show(id) {
  currentScreenId = id;
  screens.forEach((s) => s.classList.toggle("active", s.id === id));
  jumpBtns.forEach((b) => b.classList.toggle("on", b.dataset.goto === id));
  document.querySelectorAll(".tabbar .tab").forEach((t) => {
    t.classList.toggle("on", t.dataset.goto === id);
  });
  phone.classList.toggle("no-dock", id === "s-player");
  const active = document.getElementById(id);
  if (active) active.scrollTop = 0;
  // Al abrir el player con canvas ya montado (se monta aunque la pantalla
  // esté oculta) hay que recalcular la caja: con display:none no hay medidas.
  if (id === "s-player") syncCanvasBox();
}

/* ------------------------------------------------------- now playing */

function setNowPlaying(tr) {
  if (!tr || tr.id == null) return;
  nowPlaying = tr;
  const art = thumb(tr, 1);
  const big = thumb(tr, 2) || art;
  const miniArt = $("#mini-art");
  miniArt.style.backgroundImage = art ? `url('${art}')` : "";
  const plArt = $("#pl-art");
  plArt.style.backgroundImage = big ? `url('${big}')` : "";
  // Lavado ambiental: la portada desenfocada tiñe el player (estilo iOS/AM)
  $("#pl-ambient").style.backgroundImage = big ? `url('${big}')` : "";
  $("#mini-title").textContent = tr.title || "—";
  $("#mini-artist").textContent = tr.artist || "";
  $("#pl-title").textContent = tr.title || "—";
  $("#pl-artist").textContent = [tr.artist, tr.album]
    .filter(Boolean)
    .join(" • ");
  // Tiempos del scrub coherentes con la barra mock (posición ≈ 36 %)
  const dur = tr.dur || 0;
  const pos = Math.round(dur * 0.36);
  $("#pl-elapsed").textContent = dur ? fmtDur(pos) : "0:00";
  $("#pl-total").textContent = dur ? fmtDur(dur) : "—";
  $("#pl-prog").style.width = dur ? `${Math.round((pos / dur) * 100)}%` : "0%";
  $("#pl-fav").classList.toggle(
    "on",
    MET.favs.some((f) => String(f.id) === String(tr.id))
  );
  markPlaying();
  loadCanvas(tr);
  loadStream(tr);
}

/* ------------------------------------------------------------- canvas */

function setCanvasMode(on) {
  $("#s-player").classList.toggle("canvas", !!on);
}

// Altura de la caja del canvas = ancho / aspecto nativo (clamp a la altura
// del stage), igual que LayoutBuilder + AnimatedPositioned en la app.
// Si el player está oculto (display:none) no hay medidas: se reintenta en
// show('s-player').
let canvasRatio = 0;

function syncCanvasBox() {
  const box = $("#pl-art");
  const stage = $("#pl-stage");
  if (!$("#s-player").classList.contains("canvas")) return;
  const w = box.clientWidth || stage.clientWidth;
  const stageH = stage.clientHeight;
  if (!w || !stageH) return;
  const ratio = canvasRatio || 1 / 1.48;
  box.style.height = `${Math.round(Math.min(w / ratio, stageH))}px`;
}

function mountCanvas(media) {
  const box = $("#pl-art");
  const old = box.querySelector("video");
  if (old) {
    old.pause();
    old.remove();
  }
  canvasRatio = 0;
  if (!media || !media.url) {
    setCanvasMode(false);
    box.style.height = "";
    return;
  }
  // Igual que en la app: el modo "portada expandida" se activa en cuanto el
  // provider resuelve, con una altura estimada (1.48× ancho, típico 9:16)
  // hasta que el vídeo da su aspecto nativo.
  setCanvasMode(true);
  box.style.height = "";
  const v = document.createElement("video");
  v.src = media.url;
  v.muted = true;
  v.loop = true;
  v.autoplay = true;
  v.playsInline = true;
  v.setAttribute("playsinline", "");
  v.setAttribute("webkit-playsinline", "");
  v.addEventListener("loadedmetadata", () => {
    if (!box.contains(v)) return;
    canvasRatio =
      v.videoWidth && v.videoHeight ? v.videoWidth / v.videoHeight : 1 / 1.48;
    syncCanvasBox();
  });
  v.addEventListener("error", () => {
    if (!box.contains(v)) return;
    v.remove();
    setCanvasMode(false);
    box.style.height = "";
  });
  box.appendChild(v);
  syncCanvasBox();
  v.play().catch(() => {});
}

async function loadCanvas(tr) {
  const token = ++canvasToken;
  const key = String(tr.id);
  mountCanvas(null);
  let media = CANVAS[key];
  if (media === undefined) {
    try {
      const raw = await api(`/api/canvas/${key}`);
      const inner =
        raw && raw.canvas && typeof raw.canvas === "object" ? raw.canvas : raw;
      media = inner && inner.url
        ? { url: inner.url, kind: inner.kind || "mp4" }
        : null;
    } catch (_) {
      media = null;
    }
    CANVAS[key] = media;
    refreshBadges();
  }
  if (token !== canvasToken) return;
  if (!nowPlaying || String(nowPlaying.id) !== key) return;
  if (media) mountCanvas(media);
}

function refreshBadges() {
  document.querySelectorAll(".row[data-track-id]").forEach((el) => {
    const known = CANVAS[String(el.dataset.trackId)];
    const meta = el.querySelector(".meta");
    if (!meta) return;
    const has = el.querySelector(":scope > .cvb");
    if (known && !has) {
      meta.insertAdjacentHTML("afterend", '<span class="cvb">canvas</span>');
    } else if (known === null && has) {
      has.remove();
    }
  });
}

const canvasPending = new Set();

function prefetchCanvas(tracks) {
  (tracks || []).slice(0, 10).forEach((t) => {
    const key = String(t.id);
    if (CANVAS[key] !== undefined || canvasPending.has(key)) return;
    canvasPending.add(key);
    api(`/api/canvas/${key}`)
      .then((raw) => {
        const inner =
          raw && raw.canvas && typeof raw.canvas === "object" ? raw.canvas : raw;
        CANVAS[key] =
          inner && inner.url ? { url: inner.url, kind: inner.kind || "mp4" } : null;
      })
      .catch(() => {
        CANVAS[key] = null;
      })
      .finally(() => {
        canvasPending.delete(key);
        refreshBadges();
      });
  });
}

/* ------------------------------------------------------------- stream */

// GET /api/stream/{id} sólo para el indicador de fuente + calidad
// (provider • FLAC 24/96 del header y la píldora _QualityBadge). No se
// reproduce nada: se cachea por track.
const STREAM = {};
let streamToken = 0;

function qualityLabel(s) {
  const parts = [];
  const c = (s.codec || "").toUpperCase();
  if (c) parts.push(c);
  if (s.bit_depth && s.sample_rate) {
    parts.push(`${s.bit_depth}/${Math.round(s.sample_rate / 1000)}`);
  } else if (s.bitrate) {
    parts.push(`${Math.round(s.bitrate / 1000)} kbps`);
  }
  if (!parts.length && s.quality) return s.quality;
  return parts.length ? parts.join(" ") : "Auto";
}

function badgeLabel(s) {
  const c = (s.codec || "").toUpperCase();
  const q = qualityLabel(s);
  if (!c) return q;
  return q.toUpperCase().startsWith(c) ? q : `${c} ${q}`;
}

function sourceLabel(s) {
  if (!s) return "MetMusic";
  const p = (s.provider || "").toUpperCase();
  const q = qualityLabel(s);
  if (!p) return q;
  return `${p} • ${q}`;
}

function renderStream(s) {
  $("#pl-source").textContent = sourceLabel(s);
  const badge = $("#qbadge");
  if (!s) {
    badge.classList.remove("on");
    badge.hidden = true;
    $("#qprev").hidden = true;
    return;
  }
  $("#qbadge-label").textContent = badgeLabel(s);
  $("#qprev").hidden = !s.is_preview;
  badge.hidden = false;
  requestAnimationFrame(() => badge.classList.add("on"));
}

async function loadStream(tr) {
  const token = ++streamToken;
  const key = String(tr.id);
  renderStream(null);
  let s = STREAM[key];
  if (s === undefined) {
    try {
      s = await api(`/api/stream/${key}`);
    } catch (_) {
      s = null;
    }
    STREAM[key] = s;
  }
  if (token !== streamToken) return;
  if (!nowPlaying || String(nowPlaying.id) !== key) return;
  renderStream(s);
}

function markPlaying() {
  const id = nowPlaying ? String(nowPlaying.id) : null;
  document.querySelectorAll("[data-track-id]").forEach((el) => {
    el.classList.toggle(
      "playing",
      id !== null && el.dataset.trackId === id
    );
  });
}

function setPlayIcons() {
  const href = `#i-${isPlaying ? "pause" : "play"}`;
  document.querySelectorAll("#mini-toggle svg, #pl-toggle svg").forEach((svg) => {
    svg.innerHTML = `<use href="${href}"/>`;
  });
  // La portada flotante encoge al pausar (AnimatedScale 0.9 de la app);
  // con canvas activo no se aplica escala, igual que en Flutter.
  $("#s-player").classList.toggle("paused", !isPlaying);
}

/* --------------------------------------------------------- fragments */

function section(title, inner) {
  return `<div class="sec-head"><h2>${esc(title)}</h2><span class="more">Ver todo</span></div>${inner}`;
}

function rowTrack(tr, opts = {}) {
  const num =
    opts.num == null
      ? ""
      : `<span class="num"><span class="numtxt">${esc(opts.num)}</span><span class="eq"><i></i><i></i><i></i></span></span>`;
  const art = opts.art
    ? `<div class="art" ${urlStyle(thumb(tr, 1))}></div>`
    : "";
  let end = opts.end || (opts.dur ? `<span class="dur">${fmtDur(tr.dur)}</span>` : "");
  if (CANVAS[String(tr.id)]) end = `<span class="cvb">canvas</span>${end}`;
  return `<div class="row" data-track-id="${esc(tr.id)}" data-play>${num}${art}
    <div class="meta"><div class="t">${esc(tr.title)}</div><div class="s">${esc(tr.artist)}</div></div>
    ${end}</div>`;
}

function cardTrack(tr) {
  return `<div class="card" data-track-id="${esc(tr.id)}" data-play>
    <div class="art" ${urlStyle(thumb(tr, 1))}></div>
    <div class="t">${esc(tr.title)}</div><div class="s">${esc(tr.artist)}</div></div>`;
}

function cardAlbum(a) {
  return `<div class="card" data-album="${esc(a.id)}">
    <div class="art" ${urlStyle(thumb(a, 1))}></div>
    <div class="t">${esc(a.title)}</div><div class="s">${esc(a.artist)}</div></div>`;
}

function cardPlaylist(p) {
  return `<div class="card" data-playlist="${esc(p.id)}">
    <div class="art" ${urlStyle(thumb(p, 1))}></div>
    <div class="t">${esc(p.title)}</div><div class="s">${esc(p.n || 0)} canciones</div></div>`;
}

function cardArtist(a) {
  const pic = a.pic ? `url('${a.pic}')` : "none";
  return `<div class="card artist">
    <div class="art" style="background-image:${pic};background-color:#1c1c1e"></div>
    <div class="t">${esc(a.name)}</div><div class="s">Artista</div></div>`;
}

/* ------------------------------------------------------------ render */

function renderChips() {
  const labels = { chill: "Chill", workout: "Workout", focus: "Focus", party: "Party" };
  $("#chips").innerHTML = MET.moods
    .map((m, i) => {
      const label = m == null ? "Para ti" : labels[m] || m;
      return `<span class="chip${i === 0 ? " on" : ""}" data-mood="${m ?? ""}">${label}</span>`;
    })
    .join("");
}

function renderHome() {
  const h = MET.home;
  const recent = MET.history.length ? MET.history : h.charts.slice(0, 6);
  let html = "";
  html += section("Recientes", `<div class="carousel">${recent.map(cardTrack).join("")}</div>`);
  html += section("Novedades", `<div class="carousel">${h.newReleases.map(cardAlbum).join("")}</div>`);
  html += section(
    "Top canciones",
    h.charts
      .slice(0, 8)
      .map((t, i) => rowTrack(t, { num: i + 1, art: true, dur: true }))
      .join("")
  );
  html += section(
    "Artistas en tendencia",
    `<div class="carousel">${h.trending.slice(0, 10).map(cardArtist).join("")}</div>`
  );
  html += section(
    "Playlists para ti",
    `<div class="carousel">${h.editorial.map(cardPlaylist).join("")}</div>`
  );
  $("#home-sections").innerHTML = html;
  register([
    ...recent,
    ...h.charts,
    ...h.newReleases.flatMap((a) => MET.albums[a.id]?.tracks || []),
  ]);
  markPlaying();
}

function renderLibrary() {
  $("#lib-playlists").innerHTML = MET.home.editorial
    .map((p) => {
      const sub = [p.creator, `${p.n || 0} canciones`].filter(Boolean).join(" · ");
      return `<div class="pl-row" data-playlist="${esc(p.id)}">
      <div class="art" ${urlStyle(thumb(p, 1))}></div>
      <div class="meta"><div class="t">${esc(p.title)}</div>
      <div class="s">${esc(sub)}</div></div>
      <span class="ic"><svg class="i i-18"><use href="#i-more"/></svg></span></div>`;
    })
    .join("");

  $("#lib-favs").innerHTML = MET.favs
    .map((t) =>
      rowTrack(t, {
        num: "♥",
        art: true,
        end: `<span class="dur">${fmtDur(t.dur)}</span>`,
      })
    )
    .join("");

  $("#lib-hist").innerHTML = MET.history
    .map((t) => rowTrack(t, { num: "↻", art: true, dur: true }))
    .join("");

  register([...MET.favs, ...MET.history]);
  markPlaying();
}

function renderSettings() {
  const h = MET.health;
  $("#set-version").textContent = h.version || "—";
  const colors = ["b-green", "b-blue", "b-orange", "b-indigo", "b-pink"];
  const icons = ["i-wifi", "i-sliders", "i-download", "i-list", "i-more"];
  $("#set-services").innerHTML = h.services
    .map(
      (s, i) => `<div class="srow">
      <span class="sicon ${colors[i % colors.length]}"><svg class="i i-18"><use href="#${icons[i % icons.length]}"/></svg></span>
      <span class="k">${esc(s.name)}</span>
      <span class="v"><span class="dot${s.ok ? "" : " down"}"></span>${esc(s.detail || (s.ok ? "OK" : "Error"))}</span></div>`
    )
    .join("");
}

function renderRecents() {
  const artists = [...new Set(MET.home.charts.map((t) => t.artist))].slice(0, 4);
  $("#search-recents").innerHTML = artists
    .map(
      (a) => `<div class="recent" data-recent="${esc(a)}">
      <span class="ic"><svg class="i i-18"><use href="#i-clock"/></svg></span> ${esc(a)}
      <span class="x"><svg class="i i-16"><use href="#i-x"/></svg></span></div>`
    )
    .join("");
}

function renderSearchBrowse() {
  $("#search-results").hidden = true;
  $("#search-browse").hidden = false;
  $("#search-results").innerHTML = "";
}

function renderSearchLocal(q) {
  const hits = MET.corpus
    .filter((t) =>
      `${t.title} ${t.artist} ${t.album || ""}`.toLowerCase().includes(q)
    )
    .slice(0, 30);
  $("#search-results").innerHTML = hits.length
    ? `<div class="sec-head"><h2>Canciones</h2></div>` +
      hits.map((t) => rowTrack(t, { art: true, dur: true })).join("") +
      `<p class="hint">Sin conexión: solo canciones del snapshot local.</p>`
    : `<div class="empty">Sin resultados para “${esc(q)}”</div>`;
  register(hits);
  prefetchCanvas(hits);
  refreshBadges();
  markPlaying();
}

function renderSearchLive(raw, q) {
  const type = searchType;
  const tracks = (raw.tracks || []).map(normTrack).filter((t) => t && t.id);
  const albums = (raw.albums || []).map(normAlbum).filter((a) => a.id);
  const artists = (raw.artists || [])
    .map((a) => ({ id: a.artist_id, name: a.name, pic: a.picture }))
    .filter((a) => a.id);
  const playlists = (raw.playlists || [])
    .map(normPlaylist)
    .filter((p) => p.id);

  let html = "";
  if (type === "all" || type === "tracks") {
    const list = type === "all" ? tracks.slice(0, 8) : tracks;
    if (list.length) {
      html += section(
        "Canciones",
        list.map((t) => rowTrack(t, { art: true, dur: true })).join("")
      );
    }
  }
  if ((type === "all" || type === "albums") && albums.length) {
    html += section(
      "Álbumes",
      `<div class="carousel">${albums.map(cardAlbum).join("")}</div>`
    );
  }
  if ((type === "all" || type === "artists") && artists.length) {
    html += section(
      "Artistas",
      `<div class="carousel">${artists.map(cardArtist).join("")}</div>`
    );
  }
  if ((type === "all" || type === "playlists") && playlists.length) {
    html += section(
      "Playlists",
      `<div class="carousel">${playlists.map(cardPlaylist).join("")}</div>`
    );
  }
  $("#search-results").innerHTML =
    html || `<div class="empty">Sin resultados para “${esc(q)}”</div>`;
  register(tracks);
  prefetchCanvas(tracks);
  refreshBadges();
  markPlaying();
}

async function runSearch(value) {
  const q = (value ?? $("#q").value).trim();
  const token = ++searchToken;
  if (!q) {
    renderSearchBrowse();
    return;
  }
  $("#search-browse").hidden = true;
  $("#search-results").hidden = false;
  $("#search-results").innerHTML = `<div class="empty">Buscando…</div>`;
  if (live) {
    try {
      const raw = await api(
        `/api/search?q=${encodeURIComponent(q)}&type=${searchType}&limit=20`
      );
      if (token !== searchToken) return;
      renderSearchLive(raw, q);
      return;
    } catch (_) {
      /* fallback local */
    }
  }
  if (token !== searchToken) return;
  renderSearchLocal(q);
}

function renderDetail(kind, d) {
  currentDetail = { kind, d };
  const isAlbum = kind === "album";
  const art = thumb(d, 2) || thumb(d, 1);
  $("#al-art").setAttribute("style", art ? `background-image:url('${art}')` : "");
  $("#al-title").textContent = d.title || "—";
  $("#al-artist").textContent = isAlbum ? d.artist || "" : d.creator || "";
  const year = (d.release || d.created || "").slice(0, 4);
  const parts = [
    isAlbum ? "Álbum" : "Playlist",
    year,
    `${d.n || (d.tracks || []).length} canciones`,
  ].filter(Boolean);
  $("#al-meta").textContent = parts.join(" · ");
  $("#al-tracks").innerHTML = (d.tracks || [])
    .map((t) => rowTrack(t, { num: t.no || "•", dur: true }))
    .join("");
  register(d.tracks || []);
  markPlaying();
}

async function openDetail(kind, id) {
  if (currentScreenId !== "s-album") backScreen = currentScreenId;
  show("s-album");
  const cache = kind === "album" ? MET.albums : MET.playlists;
  if (cache[id]) {
    renderDetail(kind, cache[id]);
    return;
  }
  renderDetail(kind, { id, title: "Cargando…", tracks: [] });
  try {
    const raw = await api(
      kind === "album" ? `/albums/${id}` : `/playlists/${id}`
    );
    const d = kind === "album" ? normAlbumDetail(raw) : normPlaylistDetail(raw);
    cache[id] = d;
    renderDetail(kind, d);
  } catch (_) {
    renderDetail(kind, { id, title: "No se pudo cargar", artist: "—", tracks: [] });
  }
}

function renderAll() {
  renderChips();
  renderHome();
  renderLibrary();
  renderSettings();
  renderRecents();
  const q = $("#q").value || "";
  if (q.trim()) runSearch(q);
  else renderSearchBrowse();
  refreshBadges();
  if (!currentDetail && MET.hero) renderDetail("album", MET.hero);
}

/* ------------------------------------------------------- live refresh */

async function initLive() {
  const badge = $("#src-badge");
  try {
    const [home, hist, favs, health] = await Promise.all([
      api("/api/explore/home"),
      api("/api/user/history?limit=16"),
      api("/api/user/favorites?limit=16"),
      api("/api/health", { auth: false }),
    ]);
    MET.home = normalizeHome(home);
    MET.history = normalizeHistory(hist);
    MET.favs = normalizeFavs(favs);
    MET.health = {
      version: health.version,
      services: (health.services || []).map((s) => ({
        name: s.name,
        ok: s.ok,
        detail: s.detail,
      })),
    };
    MET.corpus = [
      ...MET.home.charts,
      ...MET.history,
      ...MET.favs,
      ...MET.corpus,
    ].slice(0, 400);
    live = true;
    renderAll();
    if (!nowPlaying && MET.home.charts[0]) setNowPlaying(MET.home.charts[0]);
    badge.textContent = "Boceto · datos EN VIVO del backend";
  } catch (_) {
    const date = (MET.fetchedAt || "").slice(0, 10);
    badge.textContent = `Boceto · snapshot del backend${date ? " (" + date + ")" : ""} — sin red`;
  }
}

async function loadMood(mood) {
  if (!live) return;
  try {
    const raw = await api(
      "/api/explore/home" + (mood ? `?mood=${encodeURIComponent(mood)}` : "")
    );
    MET.home = normalizeHome(raw);
    renderHome();
  } catch (_) {
    /* se queda el contenido anterior */
  }
}

/* -------------------------------------------------------- interacción */

document.addEventListener("click", (e) => {
  const toggle = e.target.closest("#mini-toggle, #pl-toggle");
  if (toggle) {
    e.stopPropagation();
    isPlaying = !isPlaying;
    setPlayIcons();
    return;
  }

  // Estados conmutables del player (boceto): favorito, aleatorio, repetir
  const state = e.target.closest("#pl-fav, #pl-shuffle, #pl-repeat");
  if (state) {
    state.classList.toggle("on");
    return;
  }

  const goto = e.target.closest("[data-goto]");
  if (goto) {
    show(goto.dataset.goto);
    return;
  }

  const swatch = e.target.closest(".swatch");
  if (swatch) {
    document.documentElement.style.setProperty("--accent", swatch.dataset.accent);
    document.querySelectorAll(".swatch").forEach((s) =>
      s.classList.toggle("on", s === swatch)
    );
    return;
  }

  const segBtn = e.target.closest("#lib-seg button, #search-types button");
  if (segBtn) {
    segBtn.parentElement
      .querySelectorAll("button")
      .forEach((b) => b.classList.toggle("on", b === segBtn));
    if (segBtn.parentElement.id === "search-types") {
      searchType = segBtn.dataset.type;
      runSearch($("#q").value);
    } else {
      document.querySelectorAll("[data-panel-for]").forEach((p) => {
        p.hidden = p.dataset.panelFor !== segBtn.dataset.panel;
      });
    }
    return;
  }

  const toggleRow = e.target.closest("[data-toggle] .sw");
  if (toggleRow) {
    toggleRow.classList.toggle("on");
    return;
  }

  const chip = e.target.closest(".chip");
  if (chip) {
    chip.parentElement.querySelectorAll(".chip").forEach((c) =>
      c.classList.toggle("on", c === chip)
    );
    loadMood(chip.dataset.mood || null);
    return;
  }

  const recent = e.target.closest("[data-recent]");
  if (recent) {
    $("#q").value = recent.dataset.recent;
    runSearch($("#q").value);
    return;
  }

  const alBack = e.target.closest("#al-back");
  if (alBack) {
    show(backScreen);
    return;
  }

  const alPlay = e.target.closest("#al-play, #al-shuffle");
  if (alPlay && currentDetail) {
    const tracks = currentDetail.d.tracks || [];
    if (tracks.length) {
      const tr =
        alPlay.id === "al-shuffle"
          ? tracks[Math.floor(Math.random() * tracks.length)]
          : tracks[0];
      setNowPlaying(tr);
    }
    return;
  }

  const playEl = e.target.closest("[data-play]");
  if (playEl) {
    const tr = TRACKS.get(String(playEl.dataset.trackId));
    if (tr) setNowPlaying(tr);
    return;
  }

  const albumEl = e.target.closest("[data-album]");
  if (albumEl) {
    openDetail("album", albumEl.dataset.album);
    return;
  }

  const playlistEl = e.target.closest("[data-playlist]");
  if (playlistEl) {
    openDetail("playlist", playlistEl.dataset.playlist);
  }
});

$("#q").addEventListener("input", (e) => {
  clearTimeout(searchDebounce);
  searchDebounce = setTimeout(() => runSearch(e.target.value), 320);
});

/* ------------------------------------------------------------- inicio */

renderAll();
register(MET.corpus);
if (MET.home.charts[0]) setNowPlaying(MET.home.charts[0]);
setPlayIcons();
const initial = location.hash.slice(1);
if (initial && document.getElementById(initial)) show(initial);
initLive();
