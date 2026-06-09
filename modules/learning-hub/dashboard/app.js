/* Awareness Portal — vanilla JS, single-user demo.
   - Discovers EVERY asset under /reports via nginx JSON autoindex (any workflow).
   - Rich Learning view from /reports/learning-hub/publications.json.
   - Tracks completion + certificates in localStorage; embeds courses in an iframe
     and listens for their postMessage completion signal.
   No per-workflow changes: anything generated appears automatically. */
(function () {
  'use strict';
  var PUBS_URL = 'reports/learning-hub/publications.json';
  var LS_NAME = 'jarvis.learner';
  var LS_PROG = 'jarvis.progress';

  var $ = function (id) { return document.getElementById(id); };
  function esc(s) { return (s == null ? '' : String(s)).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function toUrl(p) { if (!p) return ''; p = String(p); return p.charAt(0) === '/' ? p.slice(1) : p; }
  function titleCase(s) { return String(s || '').split(/[-_\s]+/).filter(Boolean).map(function (w) { return w.charAt(0).toUpperCase() + w.slice(1); }).join(' '); }

  // The shared Jarvis avatar (matches the magazine sign-off) — brand mark.
  var JARVIS = '<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="jg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0E7C86"/><stop offset="1" stop-color="#0A1A2F"/></linearGradient></defs><circle cx="32" cy="32" r="32" fill="url(#jg)"/><rect x="19" y="21" width="26" height="22" rx="7" fill="#fff"/><circle cx="27" cy="32" r="3.2" fill="#0E7C86"/><circle cx="37" cy="32" r="3.2" fill="#0E7C86"/><rect x="27" y="38" width="10" height="2.4" rx="1.2" fill="#0E7C86"/><rect x="30.7" y="14" width="2.6" height="6" rx="1.3" fill="#9fe4d8"/><circle cx="32" cy="13" r="2.4" fill="#E7C76A"/><path d="M23 47h18l-3 4.5H26z" fill="#9fe4d8"/></svg>';

  // folder -> { label, icon } (icons are simple emoji glyphs for portability)
  var CATS = {
    'posters': { label: 'Posters & Explainers', icon: '🖼️' },
    'quiz': { label: 'Quizzes', icon: '❓' },
    'tabletop': { label: 'Tabletop Exercises', icon: '🎲' },
    'tips': { label: 'Micro-tips & Cards', icon: '💡' },
    'teachable': { label: 'Teachable Moments', icon: '📣' },
    'kpi': { label: 'KPI Reports', icon: '📊' },
    'calendar': { label: 'Campaign Calendars', icon: '📅' },
    'video': { label: 'Video Storyboards', icon: '🎬' },
    'signage': { label: 'Digital Signage', icon: '🖥️' },
    'elearning': { label: 'E-learning', icon: '🎓' },
    'certificates': { label: 'Certificates', icon: '🏅' },
    'comics': { label: 'Comic Books', icon: '💥' },
    'learning-hub': { label: 'Magazines', icon: '📰' },
    'cyber-brief': { label: 'Intelligence Briefs', icon: '🛰️' },
    'defence-cyber': { label: 'Intelligence Briefs', icon: '🛰️' },
    'cyber-opportunities': { label: 'Intelligence Briefs', icon: '🛰️' },
    'energy-intelligence': { label: 'Intelligence Briefs', icon: '🛰️' }
  };
  function catFor(key) { return CATS[key] || { label: titleCase(key), icon: '📄' }; }

  /* ---- brand ---- */
  var BRAND = { brand: 'Security Awareness', tagline: 'Your one-stop awareness content portal', accent: '#0E7C86', logo: '' };
  function applyBrand() {
    $('brandAvatar').innerHTML = BRAND.logo ? ('<img src="' + esc(BRAND.logo) + '" alt=""/>') : JARVIS;
    $('heroAvatar').innerHTML = BRAND.logo ? ('<img src="' + esc(BRAND.logo) + '" alt=""/>') : JARVIS;
    ['modalAv', 'emptyLibAv', 'emptyDashAv', 'emptyCertsAv'].forEach(function (id) { if ($(id)) $(id).innerHTML = JARVIS; });
    $('brandName').textContent = BRAND.brand;
    $('footBrand').textContent = BRAND.brand;
    $('heroTitle').textContent = BRAND.brand;
    if (BRAND.tagline) { $('brandTagline').textContent = BRAND.tagline; $('heroTagline').textContent = BRAND.tagline + ' — every asset Jarvis creates, in one place.'; }
    if (BRAND.accent) document.documentElement.style.setProperty('--accent', BRAND.accent);
  }
  function loadBrand() {
    return fetch('portal.json?t=' + Date.now()).then(function (r) { return r.ok ? r.json() : null; }).catch(function () { return null; })
      .then(function (j) { if (j) BRAND = Object.assign(BRAND, j); applyBrand(); });
  }

  /* ---- store ---- */
  function getLearner() { try { return localStorage.getItem(LS_NAME) || ''; } catch (e) { return ''; } }
  function setLearner(n) { try { localStorage.setItem(LS_NAME, n); } catch (e) {} }
  function getProgress() { try { return JSON.parse(localStorage.getItem(LS_PROG) || '{}') || {}; } catch (e) { return {}; } }
  function saveProgress(p) { try { localStorage.setItem(LS_PROG, JSON.stringify(p)); } catch (e) {} }
  function recordCompletion(rec) { if (!rec || !rec.courseId) return; var p = getProgress(); p[rec.courseId] = Object.assign({ status: 'complete' }, p[rec.courseId] || {}, rec); saveProgress(p); }

  /* ---- dates ---- */
  function dayNum(d) { return Math.floor(d.getTime() / 86400000); }
  function today0() { return new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00'); }
  function fmtDate(s) { try { var d = new Date(s + 'T00:00:00'); if (isNaN(d)) d = new Date(s); var M = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return M[d.getMonth()] + ' ' + d.getDate() + ', ' + d.getFullYear(); } catch (e) { return s; } }
  function deadlineInfo(pub) {
    var rel = new Date((pub.releaseDate || '') + 'T00:00:00');
    if (isNaN(rel.getTime())) return { text: '', cls: 'ok' };
    var remaining = (pub.deadlineDays || 30) - (dayNum(today0()) - dayNum(rel));
    if (remaining > 7) return { text: remaining + ' days left to complete', cls: 'ok' };
    if (remaining >= 0) return { text: remaining + ' day' + (remaining === 1 ? '' : 's') + ' left to complete', cls: 'warn' };
    return { text: 'Overdue by ' + Math.abs(remaining) + ' day' + (Math.abs(remaining) === 1 ? '' : 's'), cls: 'over' };
  }

  /* ---- state ---- */
  var PUBS = [];
  var ASSETS = [];
  var curFilter = 'all';

  /* ================= catalog walk (nginx JSON autoindex) ================= */
  function listDir(path) {
    return fetch(path + '?t=' + Date.now()).then(function (r) {
      if (!r.ok) return [];
      return r.text().then(function (txt) {
        var t = (txt || '').trim();
        if (t.charAt(0) === '[') { try { return JSON.parse(t); } catch (e) {} }
        // fallback: parse an HTML autoindex listing
        var out = [], re = /href="([^"?#][^"]*)"/g, m;
        while ((m = re.exec(txt))) {
          var nm = decodeURIComponent(m[1]); if (nm === '../' || nm === '/') continue;
          var isDir = nm.charAt(nm.length - 1) === '/';
          out.push({ name: isDir ? nm.slice(0, -1) : nm, type: isDir ? 'directory' : 'file' });
        }
        return out;
      });
    }).catch(function () { return []; });
  }
  function walk(path, depth, acc) {
    return listDir(path).then(function (items) {
      var chain = Promise.resolve();
      items.forEach(function (it) {
        var nm = it.name; if (!nm || nm.charAt(0) === '.' || nm === 'archive') return;
        if (it.type === 'directory') { if (depth > 0) chain = chain.then(function () { return walk(path + nm + '/', depth - 1, acc); }); }
        else { acc.push({ dir: path, name: nm, size: it.size || 0, mtime: it.mtime || '' }); }
      });
      return chain;
    });
  }
  var SKIP_EXT = { json: 1, xml: 1, gitkeep: 1, txt: 1 };
  function parseAsset(a) {
    var name = a.name; var dot = name.lastIndexOf('.'); var ext = dot >= 0 ? name.slice(dot + 1).toLowerCase() : '';
    if (SKIP_EXT[ext] || name === '.gitkeep') return null;
    var key = a.dir.replace(/\/+$/, '').split('/').pop();
    var cat = catFor(key);
    var base = dot >= 0 ? name.slice(0, dot) : name;
    var dm = base.match(/(\d{4}-\d{2}-\d{2})/);
    var date = dm ? dm[1] : (a.mtime ? String(a.mtime).slice(0, 10) : '');
    // title: drop the leading tool prefix + the date, Title-Case the middle
    var PREFIX = { posters: 'poster', quiz: 'quiz', tabletop: 'tabletop', tips: 'tips', teachable: 'teachable', kpi: 'kpi', calendar: 'calendar', video: 'storyboard', signage: 'signage', certificates: 'certificate', comics: 'comic' };
    var mid = base.replace(/-?\d{4}-\d{2}-\d{2}.*$/, '').replace(/-scorm$/, '');
    var pre = PREFIX[key];
    if (pre && mid.toLowerCase().indexOf(pre + '-') === 0) mid = mid.slice(pre.length + 1);
    var title = titleCase(mid) || cat.label;
    if (key === 'learning-hub') title = 'Magazine' + (date ? ' — ' + fmtDate(date) : '');
    return { url: a.dir + name, name: name, ext: ext, catKey: key, cat: cat, title: title, date: date };
  }
  function loadCatalog() {
    var raw = [];
    return walk('reports/', 3, raw).then(function () {
      ASSETS = raw.map(parseAsset).filter(Boolean);
      ASSETS.sort(function (a, b) { return String(b.date).localeCompare(String(a.date)); });
    }).catch(function () { ASSETS = []; });
  }

  /* ================= asset cards / open ================= */
  function typeBadge(ext) {
    var m = { pdf: 'PDF', html: 'HTML', zip: 'ZIP', ics: 'ICS', png: 'IMG', jpg: 'IMG', jpeg: 'IMG' };
    return m[ext] || ext.toUpperCase();
  }
  function assetCard(a) {
    var el = document.createElement('div'); el.className = 'acard';
    var openable = (a.ext === 'pdf' || a.ext === 'html' || a.ext === 'png' || a.ext === 'jpg' || a.ext === 'jpeg');
    el.innerHTML =
      '<div class="acard-top"><span class="ico">' + a.cat.icon + '</span><span class="ext ext-' + esc(a.ext) + '">' + typeBadge(a.ext) + '</span></div>' +
      '<div class="acard-cat">' + esc(a.cat.label) + '</div>' +
      '<div class="acard-title">' + esc(a.title) + '</div>' +
      '<div class="acard-meta">' + (a.date ? esc(fmtDate(a.date)) : '') + '</div>' +
      '<div class="acard-actions">' +
      (openable ? '<button class="btn sm" data-open="1">Open</button>' : '') +
      '<a class="btn sm alt" href="' + esc(a.url) + '" download>Download</a>' +
      '</div>';
    if (openable) el.querySelector('[data-open]').onclick = function () { openAsset(a); };
    return el;
  }
  function openAsset(a) {
    $('overlayTitle').textContent = a.title + ' · ' + a.cat.label;
    var dl = $('overlayDownload'); dl.href = a.url; dl.hidden = false;
    var frame = $('courseFrame'), iw = $('imgWrap'), img = $('overlayImg');
    if (a.ext === 'png' || a.ext === 'jpg' || a.ext === 'jpeg') {
      frame.hidden = true; frame.src = 'about:blank'; img.src = a.url; iw.hidden = false;
    } else {
      iw.hidden = true; img.src = ''; frame.src = a.url; frame.hidden = false;
    }
    $('overlay').hidden = false;
  }

  /* ================= HOME ================= */
  function renderHome() {
    var prog = getProgress();
    var cats = {}; ASSETS.forEach(function (a) { cats[a.cat.label] = (cats[a.cat.label] || 0) + 1; });
    var month = new Date().toISOString().slice(0, 7);
    var thisMonth = ASSETS.filter(function (a) { return (a.date || '').slice(0, 7) === month; }).length;
    var outstanding = PUBS.filter(function (p) { var c = p.course && p.course.id; return !(c && prog[c] && prog[c].status === 'complete'); }).length;
    $('homeStats').innerHTML =
      stat(ASSETS.length, 'Total assets') +
      stat(Object.keys(cats).length, 'Categories') +
      stat(thisMonth, 'New this month') +
      stat(outstanding, 'Courses to complete');
    var recent = $('homeRecent'); recent.innerHTML = '';
    ASSETS.slice(0, 6).forEach(function (a) { recent.appendChild(assetCard(a)); });
    var cg = $('homeCats'); cg.innerHTML = '';
    Object.keys(cats).sort().forEach(function (label) {
      var any = ASSETS.find(function (a) { return a.cat.label === label; });
      var tile = document.createElement('button'); tile.className = 'cat-tile';
      tile.innerHTML = '<span class="ct-ico">' + (any ? any.cat.icon : '📄') + '</span><span class="ct-l">' + esc(label) + '</span><span class="ct-n">' + cats[label] + '</span>';
      tile.onclick = function () { switchTab('library'); setFilter(label); };
      cg.appendChild(tile);
    });
  }
  function stat(n, l) { return '<div class="stat"><div class="n">' + n + '</div><div class="l">' + l + '</div></div>'; }

  /* ================= LIBRARY ================= */
  function uniqueLabels() { var s = {}; ASSETS.forEach(function (a) { s[a.cat.label] = 1; }); return Object.keys(s).sort(); }
  function renderChips() {
    var box = $('filterChips'); box.innerHTML = '';
    var labels = ['all'].concat(uniqueLabels());
    labels.forEach(function (l) {
      var b = document.createElement('button'); b.className = 'chip' + (curFilter === l ? ' on' : '');
      b.textContent = l === 'all' ? 'All' : l; b.onclick = function () { setFilter(l); };
      box.appendChild(b);
    });
  }
  function setFilter(l) { curFilter = l; renderChips(); renderLibrary(); }
  function renderLibrary() {
    var grid = $('libGrid'), empty = $('emptyLib'); grid.innerHTML = '';
    var q = ($('searchInput').value || '').trim().toLowerCase();
    var list = ASSETS.filter(function (a) {
      if (curFilter !== 'all' && a.cat.label !== curFilter) return false;
      if (q && (a.title + ' ' + a.cat.label + ' ' + a.name).toLowerCase().indexOf(q) < 0) return false;
      return true;
    });
    empty.hidden = list.length > 0;
    list.forEach(function (a) { grid.appendChild(assetCard(a)); });
  }

  /* ================= LEARNING (publications) ================= */
  function loadPubs() {
    return fetch(PUBS_URL + '?t=' + Date.now()).then(function (r) { return r.ok ? r.json() : { publications: [] }; })
      .then(function (j) { PUBS = (j && j.publications) || []; }).catch(function () { PUBS = []; });
  }
  function renderLearning() {
    var cards = $('cards'), empty = $('emptyDash'), summary = $('summary'); cards.innerHTML = '';
    var prog = getProgress(); var done = 0;
    PUBS.forEach(function (pub) { var cid = pub.course && pub.course.id; if (cid && prog[cid] && prog[cid].status === 'complete') done++; });
    if (!PUBS.length) { empty.hidden = false; summary.innerHTML = ''; return; }
    empty.hidden = true;
    summary.innerHTML = stat(PUBS.length, 'Publications') + stat(done, 'Completed') + stat(Math.max(0, PUBS.length - done), 'Outstanding');
    PUBS.forEach(function (pub) { cards.appendChild(pubCard(pub, prog)); });
  }
  function pubCard(pub, prog) {
    var el = document.createElement('div'); el.className = 'card';
    var cid = (pub.course && pub.course.id) || ''; var rec = prog[cid]; var complete = rec && rec.status === 'complete';
    var dl = deadlineInfo(pub);
    var statusBadge = complete ? '<span class="badge done">✓ Complete · ' + (rec.score != null ? esc(rec.score) + '%' : '') + '</span>' : '<span class="badge todo">● E-learning to complete</span>';
    var deadlineLine = complete ? '<span class="deadline ok">Completed ' + esc(fmtDate(rec.date)) + '</span>' : '<span class="deadline ' + dl.cls + '">' + esc(dl.text) + '</span>';
    var magUrl = toUrl((pub.magazine && (pub.magazine.pdf || pub.magazine.html)) || '');
    el.innerHTML =
      '<div class="head"><div class="kick">Edition · ' + esc(fmtDate(pub.releaseDate)) + '</div><h3>' + esc(pub.title || 'Publication') + '</h3></div>' +
      '<div class="body"><div class="meta">' + statusBadge + deadlineLine + '</div>' +
      '<div class="meta"><span>📖 Magazine — read anytime</span></div>' +
      '<div class="actions">' +
      '<button class="btn alt" data-mag="' + esc(magUrl) + '">Read magazine</button>' +
      '<button class="btn" data-course="' + esc(cid) + '">' + (complete ? 'Revisit course' : 'Start e-learning') + '</button>' +
      '</div></div>';
    el.querySelector('[data-mag]').onclick = function () { if (magUrl) window.open(magUrl, '_blank'); else toast('Magazine not available yet'); };
    el.querySelector('[data-course]').onclick = function () { openCourse(pub); };
    return el;
  }
  function courseUrlFor(courseId) { for (var i = 0; i < PUBS.length; i++) { var c = PUBS[i].course; if (c && c.id === courseId) return toUrl(c.html); } return ''; }
  function openCourse(pub) {
    var c = pub.course || {}; var url = toUrl(c.html);
    if (!url) { toast('Course not available yet'); return; }
    var q = '?publicationId=' + encodeURIComponent(pub.id || '') + '&courseId=' + encodeURIComponent(c.id || '') + '&name=' + encodeURIComponent(getLearner());
    $('overlayTitle').textContent = (pub.title || 'Course'); $('overlayDownload').hidden = true;
    $('imgWrap').hidden = true; $('overlayImg').src = '';
    $('courseFrame').src = url + q; $('courseFrame').hidden = false; $('overlay').hidden = false;
  }

  /* ================= CERTIFICATES ================= */
  function renderCerts() {
    var wrap = $('certCards'), empty = $('emptyCerts'); wrap.innerHTML = '';
    var prog = getProgress();
    var recs = Object.keys(prog).map(function (k) { return prog[k]; }).filter(function (r) { return r && r.status === 'complete'; });
    recs.sort(function (a, b) { return String(b.date).localeCompare(String(a.date)); });
    var issued = ASSETS.filter(function (a) { return a.catKey === 'certificates'; });
    if (!recs.length && !issued.length) { empty.hidden = false; return; }
    empty.hidden = true;
    recs.forEach(function (r) { wrap.appendChild(certCard(r)); });
    issued.forEach(function (a) { wrap.appendChild(assetCard(a)); });
  }
  function certCard(r) {
    var el = document.createElement('div'); el.className = 'cert';
    el.innerHTML = '<div class="ribbon"></div><div class="c-body">' + sealSvg() +
      '<div class="c-title">Certificate of Completion</div><div class="c-for">This is proudly presented to</div>' +
      '<div class="c-name">' + esc(r.learner || getLearner() || 'Learner') + '</div>' +
      '<div class="c-for">for completing <b>' + esc(r.title || 'an awareness course') + '</b></div>' +
      '<div class="c-row"><span>Awarded <b>' + esc(fmtDate(r.date)) + '</b></span><span>Score <b>' + esc(r.score != null ? r.score + '%' : '—') + '</b></span></div>' +
      '<div class="c-actions"><button class="btn ghost" data-cert="1">View / print certificate</button></div></div>';
    el.querySelector('[data-cert]').onclick = function () { viewCert(r); };
    return el;
  }
  function sealSvg() { return '<svg class="seal" viewBox="0 0 48 48"><circle cx="24" cy="22" r="14" fill="#C9A24B"/><circle cx="24" cy="22" r="11" fill="#0E2233"/><path d="M19 36l-3 9 8-4 8 4-3-9" fill="#0E7C86"/><text x="24" y="26" text-anchor="middle" font-family="Georgia,serif" font-size="11" font-weight="bold" fill="#F6E6A8">★</text></svg>'; }
  function viewCert(rec) {
    var url = courseUrlFor(rec.courseId) || toUrl(rec.html);
    if (!url) { toast('Certificate source not available'); return; }
    $('overlayTitle').textContent = 'Certificate — ' + (rec.title || ''); $('overlayDownload').hidden = true;
    $('imgWrap').hidden = true; $('overlayImg').src = '';
    $('courseFrame').src = url + '#cert?name=' + encodeURIComponent(rec.learner || getLearner()) + '&score=' + encodeURIComponent(rec.score || 0);
    $('courseFrame').hidden = false; $('overlay').hidden = false;
  }
  function closeOverlay() { $('overlay').hidden = true; $('courseFrame').src = 'about:blank'; $('courseFrame').hidden = false; $('overlayImg').src = ''; $('imgWrap').hidden = true; }

  /* ---- completion message from an embedded course ---- */
  window.addEventListener('message', function (e) {
    var d = e && e.data; if (!d || d.type !== 'jarvis:complete' || !d.passed) return;
    recordCompletion({ courseId: d.courseId, publicationId: d.publicationId, title: d.title, learner: d.learner || getLearner(), score: d.score, date: d.date, html: courseUrlFor(d.courseId) });
    renderLearning(); renderCerts(); renderHome();
    toast('Course complete — certificate added to your library');
  });

  /* ---- ui plumbing ---- */
  function toast(msg) { var t = $('toast'); t.textContent = msg; t.hidden = false; clearTimeout(toast._t); toast._t = setTimeout(function () { t.hidden = true; }, 3200); }
  var VIEWS = { home: 'view-home', library: 'view-library', learning: 'view-learning', certs: 'view-certs' };
  function switchTab(name) {
    document.querySelectorAll('.tab').forEach(function (b) { b.classList.toggle('active', b.dataset.tab === name); });
    Object.keys(VIEWS).forEach(function (k) { $(VIEWS[k]).hidden = k !== name; });
  }
  function ensureName() { var n = getLearner(); $('whoName').textContent = n || '—'; if (!n) { $('nameModal').hidden = false; setTimeout(function () { var el = $('nameInput'); if (el) el.focus(); }, 50); } }
  function saveName() { var v = ($('nameInput').value || '').trim(); if (!v) { $('nameInput').focus(); return; } setLearner(v); $('whoName').textContent = v; $('nameModal').hidden = true; renderCerts(); }

  document.querySelectorAll('.tab').forEach(function (b) { b.onclick = function () { switchTab(b.dataset.tab); }; });
  $('overlayClose').onclick = closeOverlay;
  $('nameSave').onclick = saveName;
  $('nameInput').addEventListener('keydown', function (e) { if (e.key === 'Enter') saveName(); });
  $('changeName').onclick = function () { $('nameInput').value = getLearner(); $('nameModal').hidden = false; setTimeout(function () { $('nameInput').focus(); }, 50); };
  $('searchInput').addEventListener('input', renderLibrary);

  /* ---- init ---- */
  loadBrand();
  ensureName();
  Promise.all([loadCatalog(), loadPubs()]).then(function () {
    renderHome(); renderChips(); renderLibrary(); renderLearning(); renderCerts();
  });
})();
