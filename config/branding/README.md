# Branding assets (local)

These files live here, are **git-ignored** (public repo), are mounted into n8n at
`/config/branding/`, and are included in `./backup.sh`.

## Report chrome
| File | Role |
|------|------|
| `cover.png` | full front-cover image at the very top of the brief |
| `banner.png` | masthead header |
| `jarvis-avatar.png` | circular sign-off footer |

`.png` or `.jpg` both work; each is optional (graceful if absent). Keep them
reasonably sized (banner/cover ≈ ≤1 MB, avatar ≈256 px) so emails stay light.

## Company logos (NOC/IOC tables)
Drop small logo files in `config/branding/logos/` named by a short key the
company name contains, e.g.:

    adnoc.png  aramco.png  shell.png  bp.png  total.png  exxon.png
    chevron.png  qatarenergy.png  taqa.png  masdar.png  kuwait.png

The renderer matches a row's company to a logo when the company name contains
the key (e.g. "Saudi Aramco" → `aramco.png`, "TotalEnergies" → `total.png`).
Missing logos simply show the company name as text.
