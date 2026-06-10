# Vendored front-end libraries

| File | Library | Version | Licence | Source |
|------|---------|---------|---------|--------|
| `three.min.js` | [three.js](https://threejs.org) | r147 | MIT | `https://raw.githubusercontent.com/mrdoob/three.js/r147/build/three.min.js` |

These are mounted read-only into the n8n container at `/config/vendor/` (see
`docker-compose.yml`) so workflows can inline them into self-contained HTML
deliverables (e.g. the Learning Hub e-learning game) without any runtime CDN
dependency — packages keep working inside locked-down LMS/corporate networks.

r147 is the last three.js release shipping a UMD `three.min.js` build, which is
what single-file inlining needs (newer releases are ES-modules only).
