// Provider de letras contra el backend de MetMusic.
// GET {apiBase}/api/lyrics/{trackId} con Bearer token.
// Normaliza synced_lines / JSON estructurado / LRC extendido a TTML.

interface MetMusicWord {
  text?: string;
  time_ms?: number;
  start_ms?: number;
  duration_ms?: number;
}

interface MetMusicBackgroundLine {
  text?: string;
  time_ms?: number;
  start_ms?: number;
  end_ms?: number;
  duration_ms?: number;
}

interface MetMusicSyncedLine {
  text?: string;
  time_ms?: number;
  start_ms?: number;
  end_ms?: number;
  duration_ms?: number;
  words?: MetMusicWord[];
  background?: MetMusicBackgroundLine[];
  agent?: string;
  is_instrumental?: boolean;
}

interface MetMusicPayload {
  sync_level?: string;
  synced_lines?: MetMusicSyncedLine[];
  lines?: MetMusicSyncedLine[];
  ttml?: string;
  lrc?: string;
  provider?: string;
  language?: string;
  offset_ms?: number;
}

export interface MetMusicFetchConfig {
  trackId: string;
  apiBase: string;
  apiToken: string;
  signal?: AbortSignal;
}

export interface MetMusicLyricsResult {
  ttml: string;
  provider: string;
  language?: string;
  offsetMs: number;
}

const XML_ESCAPES: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&apos;',
};

const escapeXml = (s: string): string =>
  s.replace(/[&<>"']/g, (c) => XML_ESCAPES[c]);

const msToTimestamp = (ms: number): string => {
  const safe = Number.isFinite(ms) && ms > 0 ? ms : 0;
  const totalSec = safe / 1000;
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const sInt = Math.floor(totalSec % 60);
  const frac = Math.round((totalSec - Math.floor(totalSec)) * 1000);
  return (
    [String(h).padStart(2, '0'), String(m).padStart(2, '0'), String(sInt).padStart(2, '0')].join(':') +
    '.' +
    String(Math.min(frac, 999)).padStart(3, '0')
  );
};

const lineStartMs = (line: MetMusicSyncedLine): number =>
  typeof line.time_ms === 'number'
    ? line.time_ms
    : typeof line.start_ms === 'number'
      ? line.start_ms
      : 0;

const wordStartMs = (word: MetMusicWord): number =>
  typeof word.time_ms === 'number'
    ? word.time_ms
    : typeof word.start_ms === 'number'
      ? word.start_ms
      : 0;

export function shapeSyncedLinesToTtml(
  payload: MetMusicPayload,
  lines: MetMusicSyncedLine[],
): string {
  const offset = payload.offset_ms ?? 0;
  const rendered: string[] = [];
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const begin = lineStartMs(line) + offset;
    const nextBegin =
      i + 1 < lines.length ? lineStartMs(lines[i + 1]) + offset : null;
    const declaredEnd =
      typeof line.end_ms === 'number'
        ? line.end_ms + offset
        : typeof line.duration_ms === 'number'
          ? begin + line.duration_ms
          : null;
    const words = line.words ?? [];
    const renderWords = (): string => {
      if (words.length === 0) return escapeXml(line.text || '');
      const spans: string[] = [];
      for (let w = 0; w < words.length; w += 1) {
        const word = words[w];
        const wBegin = wordStartMs(word) + offset;
        const wDeclaredEnd =
          typeof word.duration_ms === 'number' ? wBegin + word.duration_ms : null;
        const wEnd =
          wDeclaredEnd ??
          (w + 1 < words.length
            ? wordStartMs(words[w + 1]) + offset
            : declaredEnd ?? nextBegin ?? wBegin + 1000);
        spans.push(
          `<span begin="${msToTimestamp(wBegin)}" ` +
            `end="${msToTimestamp(Math.max(wEnd, wBegin + 1))}">` +
            `${escapeXml(word.text || '')}</span>`,
        );
      }
      return spans.join(' ');
    };
    const renderBackground = (): string => {
      const bg = line.background;
      if (!bg || bg.length === 0) return '';
      return bg
        .map((l) => {
          const bBegin = lineStartMs(l as MetMusicSyncedLine) + offset;
          const bEnd =
            typeof l.duration_ms === 'number'
              ? bBegin + l.duration_ms
              : typeof l.end_ms === 'number'
                ? l.end_ms + offset
                : bBegin + 2000;
          return (
            `<span ttm:role="x-bg" begin="${msToTimestamp(bBegin)}" ` +
            `end="${msToTimestamp(Math.max(bEnd, bBegin + 1))}">` +
            `${escapeXml(l.text || '')}</span>`
          );
        })
        .join('');
    };
    const end = declaredEnd ?? nextBegin ?? begin + 3000;
    if (line.is_instrumental) {
      rendered.push(
        `<p begin="${msToTimestamp(begin)}" ` +
          `end="${msToTimestamp(Math.max(end, begin + 1))}" ` +
          `ttm:role="x-instrumental"><span></span></p>`,
      );
      continue;
    }
    const inner = renderWords();
    const bg = renderBackground();
    const agent = line.agent ? ` ttm:agent="${escapeXml(line.agent)}"` : '';
    rendered.push(
      `<p begin="${msToTimestamp(begin)}" ` +
        `end="${msToTimestamp(Math.max(end, begin + 1))}"${agent}>` +
        `${inner}${bg}</p>`,
    );
  }
  const lang = payload.language ?? 'en';
  return (
    `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<tt xmlns="http://www.w3.org/ns/ttml" ` +
    `xmlns:ttm="http://www.w3.org/ns/ttml#metadata" ` +
    `xml:lang="${escapeXml(lang)}">\n<body><div>\n` +
    `${rendered.join('\n')}\n</div></body>\n</tt>`
  );
}

export function shapeLrcToTtml(payload: MetMusicPayload): string {
  const lrc = payload.lrc ?? '';
  const offset = payload.offset_ms ?? 0;
  const lineRe = /^\[(\d+):(\d+(?:\.\d+)?)\](.*)$/;
  const wordRe = /<(\d+):(\d+(?:\.\d+)?)>([^<]*)/g;
  const rendered: string[] = [];
  const rawLines: { start: number; rest: string }[] = [];
  for (const raw of lrc.split('\n')) {
    const m = lineRe.exec(raw.trim());
    if (!m) continue;
    const start =
      (parseInt(m[1], 10) * 60 + parseFloat(m[2])) * 1000 + offset;
    rawLines.push({ start, rest: m[3] });
  }
  for (let i = 0; i < rawLines.length; i += 1) {
    const entry = rawLines[i];
    const nextStart =
      i + 1 < rawLines.length ? rawLines[i + 1].start : entry.start + 5000;
    const words: { text: string; start: number }[] = [];
    wordRe.lastIndex = 0;
    let wm: RegExpExecArray | null;
    while ((wm = wordRe.exec(entry.rest)) !== null) {
      const text = wm[3];
      if (text.trim() === '') continue;
      words.push({
        text,
        start: (parseInt(wm[1], 10) * 60 + parseFloat(wm[2])) * 1000 + offset,
      });
    }
    if (words.length === 0) {
      const text = entry.rest.replace(/<[^>]*>/g, '').trim();
      if (text === '') continue;
      rendered.push(
        `<p begin="${msToTimestamp(entry.start)}" ` +
          `end="${msToTimestamp(nextStart)}">${escapeXml(text)}</p>`,
      );
      continue;
    }
    const lineEnd = Math.max(words[words.length - 1].start + 2000, nextStart);
    const spans = words
      .map((w, index) => {
        const wEnd = index + 1 < words.length ? words[index + 1].start : lineEnd;
        return (
          `<span begin="${msToTimestamp(w.start)}" ` +
          `end="${msToTimestamp(Math.max(wEnd, w.start + 1))}">` +
          `${escapeXml(w.text)}</span>`
        );
      })
      .join(' ');
    rendered.push(
      `<p begin="${msToTimestamp(entry.start)}" ` +
        `end="${msToTimestamp(lineEnd)}">${spans}</p>`,
    );
  }
  const lang = payload.language ?? 'en';
  return (
    `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<tt xmlns="http://www.w3.org/ns/ttml" ` +
    `xmlns:ttm="http://www.w3.org/ns/ttml#metadata" ` +
    `xml:lang="${escapeXml(lang)}">\n<body><div>\n` +
    `${rendered.join('\n')}\n</div></body>\n</tt>`
  );
}

export async function fetchMetMusicLyrics(
  config: MetMusicFetchConfig,
): Promise<MetMusicLyricsResult | null> {
  const base = config.apiBase.replace(/\/+$/, '');
  const url = `${base}/api/lyrics/${encodeURIComponent(config.trackId)}`;
  const res = await fetch(url, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${config.apiToken}`,
      Accept: 'application/json',
    },
    signal: config.signal,
  });
  if (res.status === 404) return null;
  if (!res.ok) {
    throw new Error(`MetMusic lyrics ${res.status}: ${res.statusText}`);
  }
  const body = (await res.json()) as Record<string, any>;
  const payload: MetMusicPayload =
    body.lyrics && typeof body.lyrics === 'object' ? body.lyrics : body;
  const level = (payload.sync_level ?? '').toLowerCase();
  if (level === 'none' || level === 'plain') return null;
  const synced = payload.synced_lines ?? payload.lines ?? [];
  if (!payload.ttml && synced.length === 0 && !payload.lrc) return null;
  let ttml: string;
  if (payload.ttml) {
    ttml = payload.ttml;
  } else if (synced.length > 0) {
    ttml = shapeSyncedLinesToTtml(payload, synced);
  } else if (payload.lrc) {
    ttml = shapeLrcToTtml(payload);
  } else {
    return null;
  }
  return {
    ttml,
    provider: `MetMusic · ${payload.provider ?? 'unknown'}`,
    language: payload.language,
    offsetMs: payload.offset_ms ?? 0,
  };
}
