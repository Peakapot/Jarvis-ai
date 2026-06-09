/* Learning Hub dashboard — vanilla JS, single-user demo.
   Reads /reports/learning-hub/publications.json (written by the n8n workflow);
   tracks completion + certificates in localStorage; embeds the course in an
   iframe and listens for its postMessage completion signal. */
(function () {
  'use strict';
  var PUBS_URL = 'reports/learning-hub/publications.json';
  var LS_NAME = 'jarvis.learner';
  var LS_PROG = 'jarvis.progress';

  var $ = function (id) { return document.getElementById(id); };
  function esc(s) { return (s == null ? '' : String(s)).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function toUrl(p) { if (!p) return ''; p = String(p); return p.charAt(0) === '/' ? p.slice(1) : p; } // map /reports/.. -> reports/.. (nginx root)

  /* ---- store ---- */
  function getLearner() { try { return localStorage.getItem(LS_NAME) || ''; } catch (e) { return ''; } }
  function setLearner(n) { try { localStorage.setItem(LS_NAME, n); } catch (e) {} }
  function getProgress() { try { return JSON.parse(localStorage.getItem(LS_PROG) || '{}') || {}; } catch (e) { return {}; } }
  function saveProgress(p) { try { localStorage.setItem(LS_PROG, JSON.stringify(p)); } catch (e) {} }
  function recordCompletion(rec) {
    if (!rec || !rec.courseId) return;
    var p = getProgress();
    p[rec.courseId] = Object.assign({ status: 'complete' }, p[rec.courseId] || {}, rec);
    saveProgress(p);
  }

  /* ---- dates ---- */
  function dayNum(d) { return Math.floor(d.getTime() / 86400000); }
  function today0() { return new Date(new Date().toISOString().slice(0, 10) + 'T00:00:00'); }
  function deadlineInfo(pub) {
    var rel = new Date((pub.releaseDate || '') + 'T00:00:00');
    if (isNaN(rel.getTime())) return { text: '', cls: 'ok' };
    var remaining = (pub.deadlineDays || 30) - (dayNum(today0()) - dayNum(rel));
    if (remaining > 7) return { text: remaining + ' days left to complete', cls: 'ok' };
    if (remaining >= 0) return { text: remaining + ' day' + (remaining === 1 ? '' : 's') + ' left to complete', cls: 'warn' };
    return { text: 'Overdue by ' + Math.abs(remaining) + ' day' + (Math.abs(remaining) === 1 ? '' : 's'), cls: 'over' };
  }
  function fmtDate(s) { try { var d = new Date(s + 'T00:00:00'); var M = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return M[d.getMonth()] + ' ' + d.getDate() + ', ' + d.getFullYear(); } catch (e) { return s; } }

  /* ---- state ---- */
  var PUBS = [];

  function load() {
    fetch(PUBS_URL + '?t=' + Date.now()).then(function (r) { return r.ok ? r.json() : { publications: [] }; })
      .then(function (j) { PUBS = (j && j.publications) || []; renderDash(); renderCerts(); })
      .catch(function () { PUBS = []; renderDash(); renderCerts(); });
  }

  /* ---- dashboard ---- */
  function renderDash() {
    var cards = $('cards'), empty = $('emptyDash'), summary = $('summary');
    cards.innerHTML = ''; var prog = getProgress();
    var done = 0;
    PUBS.forEach(function (pub) { var cid = pub.course && pub.course.id; if (cid && prog[cid] && prog[cid].status === 'complete') done++; });
    summary.innerHTML =
      stat(PUBS.length, 'Publications') +
      stat(done, 'Completed') +
      stat(Math.max(0, PUBS.length - done), 'Outstanding');
    if (!PUBS.length) { empty.hidden = false; summary.innerHTML = ''; return; }
    empty.hidden = true;
    PUBS.forEach(function (pub) { cards.appendChild(pubCard(pub, prog)); });
  }
  function stat(n, l) { return '<div class="stat"><div class="n">' + n + '</div><div class="l">' + l + '</div></div>'; }

  function pubCard(pub, prog) {
    var el = document.createElement('div'); el.className = 'card';
    var cid = (pub.course && pub.course.id) || '';
    var rec = prog[cid];
    var complete = rec && rec.status === 'complete';
    var dl = deadlineInfo(pub);
    var statusBadge = complete
      ? '<span class="badge done">✓ Complete · ' + (rec.score != null ? esc(rec.score) + '%' : '') + '</span>'
      : '<span class="badge todo">● E-learning to complete</span>';
    var deadlineLine = complete
      ? '<span class="deadline ok">Completed ' + esc(fmtDate(rec.date)) + '</span>'
      : '<span class="deadline ' + dl.cls + '">' + esc(dl.text) + '</span>';
    var magUrl = toUrl((pub.magazine && (pub.magazine.pdf || pub.magazine.html)) || '');
    el.innerHTML =
      '<div class="head"><div class="kick">Edition · ' + esc(fmtDate(pub.releaseDate)) + '</div><h3>' + esc(pub.title || 'Publication') + '</h3></div>' +
      '<div class="body">' +
      '<div class="meta">' + statusBadge + deadlineLine + '</div>' +
      '<div class="meta"><span>📖 Magazine — read anytime</span></div>' +
      '<div class="actions">' +
      '<button class="btn alt" data-mag="' + esc(magUrl) + '">Read magazine</button>' +
      '<button class="btn" data-course="' + esc(cid) + '">' + (complete ? 'Revisit course' : 'Start e-learning') + '</button>' +
      '</div></div>';
    el.querySelector('[data-mag]').onclick = function () { if (magUrl) window.open(magUrl, '_blank'); else toast('Magazine not available yet'); };
    el.querySelector('[data-course]').onclick = function () { openCourse(pub); };
    return el;
  }

  /* ---- certificate library ---- */
  function renderCerts() {
    var wrap = $('certCards'), empty = $('emptyCerts');
    wrap.innerHTML = ''; var prog = getProgress();
    var recs = Object.keys(prog).map(function (k) { return prog[k]; }).filter(function (r) { return r && r.status === 'complete'; });
    recs.sort(function (a, b) { return String(b.date).localeCompare(String(a.date)); });
    if (!recs.length) { empty.hidden = false; return; }
    empty.hidden = true;
    recs.forEach(function (r) { wrap.appendChild(certCard(r)); });
  }
  function certCard(r) {
    var el = document.createElement('div'); el.className = 'cert';
    el.innerHTML =
      '<div class="ribbon"></div>' +
      '<div class="c-body">' + sealSvg() +
      '<div class="c-title">Certificate of Completion</div>' +
      '<div class="c-for">This is proudly presented to</div>' +
      '<div class="c-name">' + esc(r.learner || getLearner() || 'Learner') + '</div>' +
      '<div class="c-for">for completing <b>' + esc(r.title || 'an awareness course') + '</b></div>' +
      '<div class="c-row"><span>Awarded <b>' + esc(fmtDate(r.date)) + '</b></span><span>Score <b>' + esc(r.score != null ? r.score + '%' : '—') + '</b></span></div>' +
      '<div class="c-actions"><button class="btn ghost" data-cert="1">View / print certificate</button></div>' +
      '</div>';
    el.querySelector('[data-cert]').onclick = function () { viewCert(r); };
    return el;
  }
  function sealSvg() {
    return '<svg class="seal" viewBox="0 0 48 48"><circle cx="24" cy="22" r="14" fill="#C9A24B"/><circle cx="24" cy="22" r="11" fill="#0E2233"/><path d="M19 36l-3 9 8-4 8 4-3-9" fill="#0E7C86"/><text x="24" y="26" text-anchor="middle" font-family="Georgia,serif" font-size="11" font-weight="bold" fill="#F6E6A8">★</text></svg>';
  }

  /* ---- course player ---- */
  function courseUrlFor(courseId) {
    for (var i = 0; i < PUBS.length; i++) { var c = PUBS[i].course; if (c && c.id === courseId) return toUrl(c.html); }
    return '';
  }
  function openCourse(pub) {
    var c = pub.course || {};
    var url = toUrl(c.html);
    if (!url) { toast('Course not available yet'); return; }
    var q = '?publicationId=' + encodeURIComponent(pub.id || '') + '&courseId=' + encodeURIComponent(c.id || '') + '&name=' + encodeURIComponent(getLearner());
    $('overlayTitle').textContent = (pub.title || 'Course');
    $('courseFrame').src = url + q;
    $('overlay').hidden = false;
  }
  function viewCert(rec) {
    var url = courseUrlFor(rec.courseId) || toUrl(rec.html);
    if (!url) { toast('Certificate source not available'); return; }
    $('overlayTitle').textContent = 'Certificate — ' + (rec.title || '');
    $('courseFrame').src = url + '#cert?name=' + encodeURIComponent(rec.learner || getLearner()) + '&score=' + encodeURIComponent(rec.score || 0);
    $('overlay').hidden = false;
  }
  function closeCourse() { $('overlay').hidden = true; $('courseFrame').src = 'about:blank'; }

  /* ---- completion message from the embedded course ---- */
  window.addEventListener('message', function (e) {
    var d = e && e.data;
    if (!d || d.type !== 'jarvis:complete' || !d.passed) return;
    recordCompletion({ courseId: d.courseId, publicationId: d.publicationId, title: d.title, learner: d.learner || getLearner(), score: d.score, date: d.date, html: courseUrlFor(d.courseId) });
    renderDash(); renderCerts();
    toast('Course complete — certificate added to your library');
  });

  /* ---- ui plumbing ---- */
  function toast(msg) { var t = $('toast'); t.textContent = msg; t.hidden = false; clearTimeout(toast._t); toast._t = setTimeout(function () { t.hidden = true; }, 3200); }
  function switchTab(name) {
    document.querySelectorAll('.tab').forEach(function (b) { b.classList.toggle('active', b.dataset.tab === name); });
    $('view-dash').hidden = name !== 'dash';
    $('view-certs').hidden = name !== 'certs';
  }
  function ensureName() {
    var n = getLearner();
    $('whoName').textContent = n || '—';
    if (!n) { $('nameModal').hidden = false; setTimeout(function () { $('nameInput').focus(); }, 50); }
  }
  function saveName() {
    var v = ($('nameInput').value || '').trim();
    if (!v) { $('nameInput').focus(); return; }
    setLearner(v); $('whoName').textContent = v; $('nameModal').hidden = true; renderCerts();
  }

  document.querySelectorAll('.tab').forEach(function (b) { b.onclick = function () { switchTab(b.dataset.tab); }; });
  $('overlayClose').onclick = closeCourse;
  $('nameSave').onclick = saveName;
  $('nameInput').addEventListener('keydown', function (e) { if (e.key === 'Enter') saveName(); });
  $('changeName').onclick = function () { $('nameInput').value = getLearner(); $('nameModal').hidden = false; setTimeout(function () { $('nameInput').focus(); }, 50); };

  ensureName();
  load();
})();
