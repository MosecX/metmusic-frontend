#!/usr/bin/env python3
"""Extrae metadatos reales del backend MetMusic y escribe prototype/data.js.

Uso:  python3 prototype/fetch_data.py
Salida: prototype/data.js  (window.MET = {...}) — snapshot de respaldo que el
boceto usa si el fetch en vivo del navegador falla (offline / token vencido).
"""

import json
import urllib.request
from concurrent.futures import ThreadPoolExecutor

BASE = "https://tdl-qbz-api.metmusic.qzz.io"
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtZXRtdXNpYy1hZG1pbi10b2tlbiIsIm5hbWUiOiJUT0tFTiIsInJvbGUiOiJhZG1pbiIsImFwcCI6Im1ldG11c2ljLWFuZHJvaWQiLCJ2ZXJzaW9uIjoiMS4wLjAiLCJwZXJtaXNzaW9ucyI6WyJzdHJlYW0iLCJzZWFyY2giLCJtZXRhZGF0YSIsInBsYXlsaXN0cyIsImhpc3RvcnkiLCJmYXZvcml0ZXMiLCJseXJpY3MiLCJjYW52YXMiLCJleHBsb3JlIl0sImRldmljZV9pZCI6ImEzZjhjMmQxZTViNzA5NDRmNmIyYThkOWMxZTNmNWE3YjlkMGUyZjRhNjhiMGMyZDRlNmY4YTBiMmM0ZDZlOGYwIiwic2Vzc2lvbl9pZCI6IjFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzIiwiaXNzdWVkX2J5IjoibWV0bXVzaWMtYmFja2VuZCIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJ0aWVyIjoiaGlyZXMiLCJtYXhfcXVhbGl0eSI6IkhJX1JFUyIsInByb3ZpZGVycyI6WyJxb2J1eiIsInRpZGFsIl0sImZlYXR1cmVzIjpbInN0cmVhbWluZyIsIm9mZmxpbmUiLCJseXJpY3Nfc3luYyIsImNhbnZhcyIsImVxdWFsaXplciIsInNjcm9iYmxpbmciXSwiaWF0IjoxNzUwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTksIm5iZiI6MTc1MDAwMDAwMCwianRpIjoiNGY1YTZiN2M4ZDllMGYxZjJhM2I0YzVkNmU3ZjgwOTFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjAiLCJhdWQiOiJ0ZGwtcWJ6LWFwaS5tZXRtdXNpYy5xenouaW8iLCJpc3MiOiJtZXRtdXNpYy1hdXRoIiwiZXh0cmFfZGF0YSI6eyJyZWdpb24iOiJMQVRBTSIsImxhbmd1YWdlIjoiZXMiLCJ0aGVtZSI6ImRhcmsiLCJhdWRpb19jb2RlY19wcmVmZXJlbmNlIjpbImZsYWMiLCJtcDQiLCJvcHVzIl0sIm1heF9iaXRyYXRlIjo5MjE2LCJzYW1wbGVfcmF0ZXMiOls0NDEwMCw0ODAwMCw5NjAwMCwxOTIwMDBdLCJiaXRfZGVwdGhzIjpbMTYsMjQsMzJdLCJjYW52YXNfZW5hYmxlZCI6dHJ1ZSwic2VnbWVudF9wcm94eSI6ZmFsc2UsImNhY2hlX3R0bCI6MzYwMCwic2Vzc2lvbl90b2tlbiI6ImUxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzYTRiNWM2ZDdlOGY5YTBiMWMyZDNlNGY1YTZiNyIsInJlZnJlc2hfdG9rZW4iOiIxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzEiLCJhcGlfa2V5X2ludGVybmFsIjoiYTliOGM3ZDZlNWY0YTNiMmMxZDBlOWY4YTdiNmM1ZDRlM2YyYTFiMGM5ZDhlN2Y2YTViNGMzZDJlMWYwIn19.9rMELXs3SAFkQ6960Reln8keTY9fo9YgK5JcL7I1Kzw"
OUT = __file__.replace("fetch_data.py", "data.js")


def get(path, timeout=30, auth=True):
    req = urllib.request.Request(BASE + path)
    req.add_header("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) MetMusicPrototype/1.0")
    if auth:
        req.add_header("Authorization", "Bearer " + TOKEN)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)


def pick_thumb(thumbs, size):
    if not thumbs:
        return None
    exact = [t["url"] for t in thumbs if t.get("size") == f"{size}x{size}"]
    if exact:
        return exact[0]
    wanted = [t for t in thumbs if t.get("width", 0) >= size]
    pool = wanted or thumbs
    return sorted(pool, key=lambda t: t.get("width", 0))[-1 if wanted else 0]["url"]


def thumbs3(thumbs):
    if not thumbs:
        return [None, None, None]
    return [pick_thumb(thumbs, s) for s in (160, 640, 1280)]


def norm_track(t):
    if not t:
        return None
    thumbs = t.get("thumbnails")
    if not thumbs and isinstance(t.get("thumbnail"), str):
        thumbs = [{"url": t["thumbnail"], "width": 320, "height": 320, "size": "320x320"}]
    return {
        "id": t.get("track_id"),
        "title": t.get("title"),
        "artist": t.get("artist"),
        "artistId": t.get("artist_id"),
        "album": t.get("album"),
        "albumId": t.get("album_id"),
        "dur": t.get("duration_seconds"),
        "x": 1 if t.get("explicit") else 0,
        "t": thumbs3(thumbs),
    }


def norm_album(a):
    return {
        "id": a.get("album_id"),
        "title": a.get("title"),
        "artist": a.get("artist"),
        "artistId": a.get("artist_id"),
        "release": a.get("release_date"),
        "n": a.get("number_of_tracks"),
        "dur": a.get("duration_seconds"),
        "x": 1 if a.get("explicit") else 0,
        "t": thumbs3(a.get("thumbnails")),
    }


def norm_playlist(p):
    return {
        "id": p.get("playlist_id"),
        "title": p.get("title"),
        "creator": p.get("creator"),
        "desc": p.get("description"),
        "n": p.get("number_of_tracks"),
        "dur": p.get("duration_seconds"),
        "t": thumbs3(p.get("thumbnails")),
    }


def album_detail(raw):
    al = raw.get("album", raw) if isinstance(raw, dict) else raw
    base = norm_album(al)
    base["genre"] = al.get("genre")
    base["label"] = al.get("label")
    tracks = [norm_track(t) for t in al.get("tracks", [])]
    for i, tr in enumerate(tracks, 1):
        if tr:
            tr["no"] = i
            if not any(tr["t"]):
                tr["t"] = base["t"]
    base["tracks"] = [t for t in tracks if t][:40]
    return base


def playlist_detail(raw):
    base = norm_playlist(raw)
    tracks = [norm_track(t) for t in raw.get("tracks", [])]
    for i, tr in enumerate(tracks, 1):
        if tr:
            tr["no"] = i
    base["tracks"] = [t for t in tracks if t][:40]
    return base


def main():
    home = get("/api/explore/home")
    sections = {s["id"]: s for s in home.get("sections", [])}

    with ThreadPoolExecutor(max_workers=6) as ex:
        f_hist = ex.submit(get, "/api/user/history?limit=16")
        f_favs = ex.submit(get, "/api/user/favorites?limit=16")
        f_health = ex.submit(lambda: get("/api/health", auth=False))

        albums = [norm_album(i) for i in sections.get("new_releases", {}).get("items", [])]
        album_ids = [a["id"] for a in albums if a["id"]]
        f_albums = {aid: ex.submit(lambda i=aid: get(f"/api/albums/{i}")) for aid in album_ids}

        playlists = [norm_playlist(i) for i in sections.get("editorial_playlists", {}).get("items", [])]
        pl_ids = [p["id"] for p in playlists if p["id"]]
        f_pls = {pid: ex.submit(lambda i=pid: get(f"/api/playlists/{i}")) for pid in pl_ids}

        history_raw = f_hist.result()
        favs_raw = f_favs.result()
        health = f_health.result()

        albums_detail = {}
        for aid, f in f_albums.items():
            try:
                albums_detail[aid] = album_detail(f.result())
            except Exception:
                pass

        playlists_detail = {}
        for pid, f in f_pls.items():
            try:
                playlists_detail[pid] = playlist_detail(f.result())
            except Exception:
                pass

    def unwrap_track(item):
        t = item.get("track") if isinstance(item, dict) else None
        return norm_track(t if isinstance(t, dict) else item)

    history = []
    for item in history_raw if isinstance(history_raw, list) else []:
        tr = unwrap_track(item)
        if tr:
            tr["playedAt"] = (item.get("played_at") or "")[:16].replace("T", " ")
            history.append(tr)

    favs = []
    for item in favs_raw if isinstance(favs_raw, list) else []:
        tr = unwrap_track(item)
        if tr:
            tr["addedAt"] = (item.get("added_at") or "")[:10]
            favs.append(tr)

    charts = [norm_track(t) for t in sections.get("charts_tracks", {}).get("items", [])]
    charts = [t for t in charts if t]
    artists = [
        {
            "id": a.get("artist_id"),
            "name": a.get("name"),
            "pic": a.get("picture"),
        }
        for a in sections.get("trending_artists", {}).get("items", [])
    ]

    # Corpus de búsqueda: todo track conocido, deduplicado.
    corpus = {}
    pools = [charts, history, favs]
    pools += [d.get("tracks", []) for d in albums_detail.values()]
    pools += [d.get("tracks", []) for d in playlists_detail.values()]
    for pool in pools:
        for t in pool:
            if t and t.get("id"):
                corpus[t["id"]] = t
    corpus_list = list(corpus.values())[:200]

    # Canvas de los tracks más visibles (el player muestra el vídeo en loop).
    canvas_ids = list(
        dict.fromkeys(
            [t["id"] for t in charts + history + favs + corpus_list[:60] if t.get("id")]
        )
    )[:90]

    def fetch_canvas(tid):
        try:
            raw = get(f"/api/canvas/{tid}", timeout=15)
            inner = raw.get("canvas") if isinstance(raw.get("canvas"), dict) else raw
            if inner and inner.get("url"):
                return tid, {
                    "url": inner["url"],
                    "kind": inner.get("kind", "mp4"),
                    "provider": inner.get("provider"),
                }
        except Exception:
            pass
        return tid, None

    canvas = {}
    with ThreadPoolExecutor(max_workers=10) as ex:
        for tid, media in ex.map(fetch_canvas, canvas_ids):
            if media:
                canvas[tid] = media

    hero = None
    for a in albums_detail.values():
        if 6 <= len(a.get("tracks", [])) <= 16:
            hero = a
            break
    if hero is None and albums_detail:
        hero = next(iter(albums_detail.values()))

    data = {
        "fetchedAt": health.get("timestamp", ""),
        "moods": [None, "chill", "workout", "focus", "party"],
        "home": {
            "newReleases": albums,
            "charts": charts,
            "editorial": playlists,
            "trending": artists,
        },
        "history": history,
        "favs": favs,
        "health": {
            "version": health.get("version"),
            "services": [
                {"name": s.get("name"), "ok": s.get("ok"), "detail": s.get("detail")}
                for s in health.get("services", [])
            ],
        },
        "albums": albums_detail,
        "playlists": playlists_detail,
        "hero": hero,
        "corpus": corpus_list,
        "canvas": canvas,
    }

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("// Generado por prototype/fetch_data.py — metadatos reales del backend.\n")
        f.write("window.MET = ")
        json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        f.write(";\n")

    print(f"{OUT}: {len(albums_detail)} álbumes, {len(playlists_detail)} playlists, "
          f"{len(charts)} charts, {len(history)} historial, {len(favs)} favoritos, "
          f"corpus {len(corpus_list)}, canvas {len(canvas)}")


if __name__ == "__main__":
    main()
