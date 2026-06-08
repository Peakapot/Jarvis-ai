# awareness · video-script

System prompt for the Video Script & Storyboard generator (embedded in the AI
nodes of `workflows/awareness/video-script.json`). The AI acts as a scriptwriter
and returns a single JSON object:

```
{ title, hook,
  scenes:[ { visual, voiceover, onScreen, seconds } ],  // 4-7 scenes, timings sum near the target
  cta }
```

`Render HTML` builds a **storyboard PDF** of scene cards (visual frame · voiceover
· on-screen caption · timing) via Gotenberg to `/reports/awareness/video/`.
Tailored to the chosen **Audience** and **Length (seconds)**. Produces the
script/storyboard only — not a rendered video.
