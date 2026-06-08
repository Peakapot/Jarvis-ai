# awareness · signage-slides

System prompt for the Digital-Signage Slides generator (embedded in the AI nodes
of `workflows/awareness/signage-slides.json`). The AI returns a single JSON
object sized to the requested slide count:

```
{ title, slides:[ { headline, sub, points[] } ] }   // exactly N slides
```

Each slide is short and readable from across a room. `Render Slides` builds one
**1920×1080 HTML page per slide** (bold headline, supporting line, up to two tip
pills, brand + page number) and emits one item per slide. **Gotenberg's
screenshot endpoint** (`/forms/chromium/screenshot/html`, `format=png`,
1920×1080) renders each to a PNG, and a pure-JS store ZIP writer bundles them
into a `.zip` written to `/reports/awareness/signage/` and returned in chat.
Tailored to the chosen **Audience**; slide count is capped at 10.
