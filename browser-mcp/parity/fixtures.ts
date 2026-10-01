// Fixture site for the parity scenarios (see SCENARIOS.md).
//
// One Bun.serve per run, on a random free port. Pages are inline HTML. The
// server keeps an in-memory event log: pages POST {event, value} to /log, and
// server-side hits (visits, counter, form bodies, uploads, User-Agent) are
// recorded directly. A log line reads `<event> <value>` (for example `visit b`).
// Read it in process (`fx.log`) or over HTTP (`GET /__log`).

import { createHash } from "node:crypto";
import { deflateSync } from "node:zlib";

export interface LogEntry {
  event: string;
  value: string;
  src: "page" | "server";
  at: number;
}

export interface Fixtures {
  port: number;
  base: string;
  log: LogEntry[];
  /** Clear the log and the /counter state, so one server can serve several scenarios. */
  reset(): void;
  stop(): void;
}

// Solid-color PNG (LCP ignores SVG images, so the LCP image must be a raster).
function solidPng(w: number, h: number, [r, g, b]: [number, number, number]): Buffer {
  const crcTable = Array.from({ length: 256 }, (_, n) => {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    return c >>> 0;
  });
  const crc = (buf: Buffer) => {
    let c = 0xffffffff;
    for (const x of buf) c = crcTable[(c ^ x) & 255]! ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  };
  const chunk = (type: string, data: Buffer) => {
    const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
    const out = Buffer.alloc(body.length + 8);
    out.writeUInt32BE(data.length, 0);
    body.copy(out, 4);
    out.writeUInt32BE(crc(body), body.length + 4);
    return out;
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  const row = Buffer.alloc(1 + w * 3);
  for (let x = 0; x < w; x++) row.set([r, g, b], 1 + x * 3);
  const raw = Buffer.concat(Array.from({ length: h }, () => row));
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk("IHDR", ihdr),
    chunk("IDAT", deflateSync(raw)),
    chunk("IEND", Buffer.alloc(0)),
  ]);
}
const LCP_PNG_PARAMS = { w: 800, h: 500, rgb: [42, 157, 143] as [number, number, number] };
const LCP_PNG = solidPng(LCP_PNG_PARAMS.w, LCP_PNG_PARAMS.h, LCP_PNG_PARAMS.rgb);
/** Delay of /assets/r4.js; the route and the fingerprint both read it. */
const SLOW_RESOURCE_MS = 1500;

// Handler-generated pages. The serving code calls these, and the fingerprint hashes their source, so a template change is detected.
const DYNAMIC = {
  "/submit": () => page("Thanks", `<h1>Thanks</h1>`, { prelude: false }),
  "/controls": () => page("Thanks", `<h1>Thanks</h1>`, { prelude: false }),
  "/upload": () => page("Uploaded", `<h1>Uploaded</h1>`, { prelude: false }),
  "/counter": (n: number) => page("Counter", `<h1 id="n">${n}</h1>`, { prelude: false }),
  "/ua": (ua: string) =>
    page("UA", `<div id="out">${ua.includes("ParityBot/1.0") ? "UA-PARITY-OK" : "UA-PARITY-NO"}</div>`, { prelude: false }),
  "/storage": () => ({ "set-cookie": "session=SESS-17; HttpOnly; Path=/" }),
};

// The runtime-only answers (leak class name, listener target) are built in script, so they are not in any served source.
const LISTENER_JS = `var t=['g','o'].join(''),m=['GO','CLICKED'].join('-');
document.getElementById(t).addEventListener('click',function(){console.log(m);L(m,'')});`;

// Shared page prelude: L(event, value) posts to /log.
const PRELUDE = `<script>function L(e,v){return fetch('/log',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({event:e,value:v==null?'':String(v)}),keepalive:true}).catch(function(){})}</script>`;

const page = (title: string, body: string, opts: { head?: string; prelude?: boolean } = {}) =>
  `<!doctype html><html><head><meta charset="utf-8"><title>${title}</title>${opts.head ?? ""}${
    opts.prelude === false ? "" : PRELUDE
  }</head><body>${body}</body></html>`;

const words = ["APPLE", "BANANA", "CHERRY", "DATE", "FIG", "GRAPE", "LEMON", "MANGO", "PEACH", "PLUM"];
const scrollPage = page(
  "Scroll",
  `<div id="list"></div><div id="sentinel" style="height:10px"></div>
<script>
var words=${JSON.stringify(words)}, n=0, MAX=100;
function more(){ var l=document.getElementById('list'); for(var i=0;i<10&&n<MAX;i++){ n++; var d=document.createElement('div'); d.className='row'; d.style.cssText='height:100px;border-bottom:1px solid #ccc'; d.textContent='Item '+n+': '+(n===47?'KIWI':words[n%words.length]); l.appendChild(d);} }
more();
new IntersectionObserver(function(es){ if(es.some(function(e){return e.isIntersecting})) more(); }).observe(document.getElementById('sentinel'));
</script>`,
);

const leakPage = page(
  "Leak",
  `<button id="leak">Leak</button><div id="out"></div>
<script>
var N=String.fromCharCode(76,101,97,107,121,84,104,105,110,103);
var K=eval('(class '+N+' { constructor(i){ this.i=i; this.payload=new Array(16).fill(i); } })');
window.__leak=[]; window.__detached=[];
document.getElementById('leak').addEventListener('click',function(){
  for(var i=0;i<1000;i++) window.__leak.push(new K(i));
  for(var j=0;j<100;j++){ var d=document.createElement('div'); d.textContent='detached '+j; window.__detached.push(d); }
  document.getElementById('out').textContent='clicked';
});
</script>`,
);

const visualPage = page(
  "Visual",
  `<canvas id="c" width="600" height="400" style="display:block"></canvas>
<script>
var x=document.getElementById('c').getContext('2d');
x.fillStyle='#fff'; x.fillRect(0,0,600,400);
x.fillStyle='rgb(255,0,0)'; x.fillRect(50,50,300,300);
x.fillStyle='rgb(0,0,255)'; x.fillRect(450,50,40,40);
</script>`,
  { head: "<style>body{margin:0}</style>" },
);

const routes: Record<string, string> = {
  "/title": page("Parity Fixture 7Q", `<h1>Title page</h1>`),
  "/links": page("Links 50", `<h1>Links</h1><a href="/docs" target="_blank">Docs</a>`),
  "/docs": page("Docs 51", `<h1>Docs</h1>`),
  "/delayed": page(
    "Delayed",
    `<div id="code">loading...</div><script>setTimeout(function(){document.getElementById('code').textContent='READY-83'},2500)</script>`,
  ),
  "/a11y": page(
    "A11y",
    `<h1>Checkout</h1><button aria-label="Submit order 19"><svg width="16" height="16" viewBox="0 0 16 16"><path d="M2 8l4 4 8-8" stroke="black" fill="none"/></svg></button>`,
  ),
  "/table": page(
    "Table",
    `<table border="1"><thead><tr><th>Item</th><th>Amount</th></tr></thead><tbody>
<tr><td>Alpha</td><td>$100</td></tr><tr><td>Beta</td><td>$250</td></tr><tr><td>Gamma</td><td>$75</td></tr>
<tr><td>Delta</td><td>$300</td></tr><tr><td>Epsilon</td><td>$209</td></tr><tr><td>Zeta</td><td>$300</td></tr></tbody></table>`,
  ),
  "/frame": page("Frame", `<h1>Outer</h1><iframe src="/frame-inner" width="400" height="120"></iframe>`),
  "/frame-inner": page("Inner", `<p id="secret">FRAME-SECRET-5</p>`),
  "/shadow": page(
    "Shadow",
    `<x-card></x-card><script>customElements.define('x-card',class extends HTMLElement{constructor(){super();this.attachShadow({mode:'open'}).innerHTML='<p>SHADOW-42</p>'}})</script>`,
  ),
  "/form": page(
    "Form",
    `<form method="post" action="/submit"><label for="name">Name</label><input id="name" name="name"><br><label for="email">Email</label><input id="email" name="email" type="email"><br><button type="submit">Submit</button></form>`,
  ),
  "/controls": page(
    "Controls",
    `<form method="post" action="/controls">
<label for="color">Color</label><select id="color" name="color"><option value="red">Red</option><option value="green">Green</option><option value="blue">Blue</option></select><br>
<label><input type="checkbox" name="subscribe"> Subscribe</label><br>
<label><input type="radio" name="size" value="small"> Small</label>
<label><input type="radio" name="size" value="medium"> Medium</label>
<label><input type="radio" name="size" value="large"> Large</label><br>
<button type="submit">Submit</button></form>`,
  ),
  "/hover": page(
    "Hover",
    `<span id="help" tabindex="0" style="display:inline-block;width:24px;height:24px;border:1px solid #333;border-radius:12px;text-align:center">?</span> <span id="tip"></span>
<script>var h=document.getElementById('help'),t=document.getElementById('tip');h.addEventListener('mouseenter',function(){t.textContent='TIP-77';L('hovered','')});h.addEventListener('mouseleave',function(){t.textContent=''});</script>`,
  ),
  "/drag": page(
    "Drag",
    `<div id="card" draggable="true" style="width:120px;height:60px;background:#9cf;margin:10px">Card</div>
<div id="zone" style="width:200px;height:120px;border:2px dashed #333;margin:10px">Drop zone</div>
<script>var z=document.getElementById('zone');
document.getElementById('card').addEventListener('dragstart',function(e){e.dataTransfer.setData('text/plain','card')});
z.addEventListener('dragover',function(e){e.preventDefault()});
z.addEventListener('drop',function(e){e.preventDefault();z.textContent='Dropped!';L('dropped','')});</script>`,
  ),
  "/keys": page(
    "Keys",
    `<div id="modal" role="dialog" aria-label="Settings" style="border:2px solid #333;padding:20px;margin:20px">Settings modal. Press a key to close it.</div><div id="status"></div>
<script>document.addEventListener('keydown',function(e){if(e.key==='Escape'){var m=document.getElementById('modal');if(m){m.remove();L('escape','');document.getElementById('status').textContent='closed'}}});</script>`,
  ),
  "/upload": page(
    "Upload",
    `<form method="post" action="/upload" enctype="multipart/form-data"><label for="f">File</label><input id="f" type="file" name="f"><button type="submit">Upload</button></form>`,
  ),
  "/dialog": page(
    "Dialog",
    `<button id="del">Delete</button><div id="out"></div>
<script>document.getElementById('del').addEventListener('click',function(){var r=confirm('Delete item 12?');document.getElementById('out').textContent='confirm '+r;L('confirm',r)});</script>`,
  ),
  "/prompt": page(
    "Prompt",
    `<button id="go">Enter code</button><div id="out"></div>
<script>document.getElementById('go').addEventListener('click',function(){var r=prompt('Your code?');document.getElementById('out').textContent='prompt '+r;L('prompt',r)});</script>`,
  ),
  "/dbl": page(
    "Double click",
    `<div id="box" style="width:160px;height:80px;background:#fc9;user-select:none">Box</div>
<script>var b=document.getElementById('box');b.addEventListener('click',function(){L('click','')});b.addEventListener('dblclick',function(){L('dblclick','')});</script>`,
  ),
  "/scroll": scrollPage,
  "/console": page(
    "Console",
    `<p>Console page</p><script>console.info('PARITY_INFO');console.error('PARITY_ERR_1');console.warn('PARITY_WARN_1');console.error('PARITY_ERR_2');console.warn('PARITY_WARN_2');</script>`,
  ),
  "/exception": page(
    "Exception",
    `<p>Exception page</p><script>function explodeHere(){throw new Error('KABOOM-6')}window.addEventListener('load',function(){setTimeout(explodeHere,100)});</script>`,
  ),
  "/requests": page(
    "Requests",
    `<p>Requests page</p><script>['/api/ok','/api/broken','/api/missing'].forEach(function(u){fetch(u).catch(function(){})});</script>`,
  ),
  "/token": page("Token", `<p>Token page</p><script>fetch('/api/token').then(function(r){return r.json()});</script>`),
  "/header": page("Header", `<p>Header page</p><script>fetch('/api/echo',{headers:{'x-parity':'99'}});</script>`),
  "/save": page(
    "Save",
    `<p>Save page</p><script>fetch('/api/save',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({draft:'DRAFT-204'})});</script>`,
  ),
  "/items": page(
    "Items",
    `<style>.hide{display:none}</style><ul>${Array.from(
      { length: 17 },
      (_, i) => `<li class="item${i % 4 === 3 ? " hide" : ""}">Item ${i + 1}</li>`,
    ).join("")}</ul>`,
  ),
  "/style": page(
    "Style",
    `<style>:root{--danger:#d62828}.msg{color:blue;font-weight:bold}.alert{color:var(--danger)}</style><p id="warn" class="msg alert">Warning!</p>`,
  ),
  "/listeners": page(
    "Listeners",
    `<button id="stop">Action</button> <button id="go">Action</button> <button id="wait">Action</button>
<script src="/assets/l.js"></script>`,
  ),
  "/cascade": page(
    "Cascade",
    `<style>@layer base{.card{max-width:900px}}.layout .card{max-width:400px}.card{background:#eef;padding:8px}</style><div class="layout"><div class="card">Card text</div></div>`,
  ),
  "/storage": page("Storage", `<p>Storage page</p><script>localStorage.setItem('parity','LS-63');</script>`),
  "/responsive": page(
    "Responsive",
    `<div id="layout"></div><script>var q=matchMedia('(max-width:499px)');function u(){document.getElementById('layout').textContent=q.matches?'MOBILE-LAYOUT':'DESKTOP-LAYOUT';if(q.matches)L('viewport',innerWidth)}q.addEventListener('change',u);addEventListener('resize',u);u();</script>`,
  ),
  "/scheme": page(
    "Scheme",
    `<div id="out"></div><script>var q=matchMedia('(prefers-color-scheme: dark)');function u(){document.getElementById('out').textContent=q.matches?'DARK-ON':'LIGHT-ON';if(q.matches)L('scheme','dark')}q.addEventListener('change',u);u();</script>`,
  ),
  "/offline": page(
    "Offline",
    `<div id="banner"></div><script>
var shown=false;function show(){document.getElementById('banner').textContent='OFFLINE-BANNER';if(!shown){shown=true;L('offline','1')}}
addEventListener('offline',show);if(!navigator.onLine)show();
setInterval(function(){fetch('/api/ping',{cache:'no-store'}).catch(show)},300);</script>`,
  ),
  "/geo": page(
    "Geo",
    `<div id="out">waiting</div><script>
navigator.geolocation.getCurrentPosition(function(p){document.getElementById('out').textContent=p.coords.latitude+', '+p.coords.longitude;L('geo',p.coords.latitude+','+p.coords.longitude)},function(e){document.getElementById('out').textContent='error: '+e.message},{timeout:8000});</script>`,
  ),
  "/print": page(
    "Print",
    `<style>.p{display:none}@media print{.p{display:block}}</style><p>Screen content</p><div class="p">PRINT-ONLY-8</div><script>var pq=matchMedia('print');function pl(){if(pq.matches)L('print','1')}pq.addEventListener('change',pl);addEventListener('beforeprint',function(){L('print','1')});pl();</script>`,
  ),
  "/perf": page(
    "Perf",
    `<link rel="stylesheet" href="/assets/r1.css"><h1>Perf</h1><script src="/assets/r4.js"></script><img src="/assets/r3.svg" width="20" height="20"><script src="/assets/r2.js"></script>`,
  ),
  "/lcp": page(
    "LCP",
    `<img id="i7" src="/assets/p9.png" width="800" height="500"><p id="t3">small text</p>`,
  ),
  "/leak": leakPage,
  "/visual": visualPage,
};
routes["/a"] = page("Page A", `<h1>Page A heading</h1><a href="/b">Go to Page B</a>`);
routes["/b"] = page("Page B", `<h1>Page B heading</h1><a href="/a">Back to Page A</a>`);

const html = (body: string, init: ResponseInit = {}) =>
  new Response(body, { ...init, headers: { "content-type": "text/html; charset=utf-8", ...(init.headers ?? {}) } });

const formLine = (fd: FormData) =>
  [...fd.entries()].filter(([, v]) => typeof v === "string").map(([k, v]) => `${k}=${v}`).join("&");

/** Hash of what a scenario's page serves: its route HTML plus the runtime assets that carry the answer. A saved run whose fingerprint differs was graded against a different page. */
export function fixtureFingerprint(id: string, prompt: string): string {
  const path = "/" + (/<BASE>\/([\w-]+)/.exec(prompt)?.[1] ?? "");
  const extra: Record<string, string> = {
    "event-listener": LISTENER_JS,
    "lcp-element": JSON.stringify(LCP_PNG_PARAMS),
    "slow-resource": `r4.js delayed ${SLOW_RESOURCE_MS}ms`,
  };
  const dynamic = (DYNAMIC as Record<string, Function>)[path]?.toString() ?? "";
  return createHash("sha256")
    .update(`${id}\n${prompt}\n${routes[path] ?? ""}\n${extra[id] ?? ""}\n${dynamic}`)
    .digest("hex")
    .slice(0, 16);
}

export function startFixtures(): Fixtures {
  const log: LogEntry[] = [];
  let counter = 0;
  const add = (event: string, value: string, src: LogEntry["src"]) => log.push({ event, value, src, at: Date.now() });

  const server = Bun.serve({
    port: 0,
    hostname: "127.0.0.1",
    async fetch(req) {
      const u = new URL(req.url);
      const p = u.pathname;
      if (p === "/__log") return Response.json(log);
      if (p === "/favicon.ico") return new Response(null, { status: 204 });
      if (p === "/log" && req.method === "POST") {
        const b = (await req.json().catch(() => ({}))) as { event?: string; value?: unknown };
        add(String(b.event ?? ""), b.value == null ? "" : String(b.value), "page");
        return new Response(null, { status: 204 });
      }
      if (p === "/assets/l.js") return new Response(LISTENER_JS, { headers: { "content-type": "application/javascript" } });
      if (p === "/assets/r4.js") {
        await Bun.sleep(SLOW_RESOURCE_MS);
        return new Response("window.__slow=1;", { headers: { "content-type": "application/javascript" } });
      }
      if (p === "/assets/r1.css") return new Response("h1{color:#333}", { headers: { "content-type": "text/css" } });
      if (p === "/assets/r2.js") return new Response("window.__fast=1;", { headers: { "content-type": "application/javascript" } });
      if (p === "/assets/p9.png") return new Response(new Uint8Array(LCP_PNG), { headers: { "content-type": "image/png" } });
      if (p === "/assets/r3.svg") {
        return new Response(
          `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20"><rect width="100%" height="100%" fill="#e76f51"/></svg>`,
          { headers: { "content-type": "image/svg+xml" } },
        );
      }
      if (p.startsWith("/api/")) {
        switch (p) {
          case "/api/ok": return Response.json({ ok: true });
          case "/api/broken": return Response.json({ error: "boom" }, { status: 500 });
          case "/api/missing": return Response.json({ error: "not found" }, { status: 404 });
          case "/api/token": return Response.json({ token: "token-XYZ-88" });
          case "/api/echo": return Response.json({ got: req.headers.get("x-parity") });
          case "/api/ping": return Response.json({ pong: true });
          case "/api/save": {
            add("save", await req.text(), "server");
            return Response.json({ saved: true });
          }
        }
        return Response.json({ error: "unknown" }, { status: 404 });
      }
      if (p === "/submit" && req.method === "POST") {
        add("submit", formLine(await req.formData()), "server");
        return html(DYNAMIC["/submit"]());
      }
      if (p === "/controls" && req.method === "POST") {
        add("controls", formLine(await req.formData()), "server");
        return html(DYNAMIC["/controls"]());
      }
      if (p === "/upload" && req.method === "POST") {
        const f = (await req.formData()).get("f");
        add("upload", f instanceof File ? `${f.name}:${await f.text()}` : "(no file)", "server");
        return html(DYNAMIC["/upload"]());
      }
      if (p === "/counter") {
        counter++;
        add("counter", String(counter), "server");
        return html(DYNAMIC["/counter"](counter));
      }
      if (p === "/ua") {
        const ua = req.headers.get("user-agent") ?? "";
        add("ua", ua, "server");
        return html(DYNAMIC["/ua"](ua));
      }
      if (p === "/storage") {
        return html(routes["/storage"]!, { headers: DYNAMIC["/storage"]() });
      }
      if (req.method === "GET" && (p === "/a" || p === "/b")) add("visit", p.slice(1), "server");
      const body = routes[p];
      return body === undefined ? new Response("not found", { status: 404 }) : html(body);
    },
  });

  return {
    port: server.port as number,
    base: `http://127.0.0.1:${server.port}`,
    log,
    reset() {
      log.length = 0;
      counter = 0;
    },
    stop() {
      server.stop(true);
    },
  };
}
