# meeting-assistant — Architecture & Notes

Transcript/notes in, structured record out (summary + decisions + action items).

## Where this module fits

```
Telegram / Webhook (transcript)  ->  summarize.json  ->  AI Provider Abstraction
                                          |
                                  Prompt: meeting.summarize-transcript
                                          |
                                  Summary + Decisions + Action items
```

## Design principles followed
- **Separation of concerns** — config, prompt, workflow, docs, health checks isolated here.
- **Provider abstraction** — summarisation routes through the core AI abstraction.
- **Configuration over hard coding** — output format is env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.

## Open questions for implementation
- Transcript source: pasted text vs. uploaded audio (would add a transcription step).
- Long-transcript handling (chunked map-reduce summarisation).
- Optional push of action items to a task system (future integration).
