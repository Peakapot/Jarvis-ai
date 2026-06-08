# awareness · campaign-calendar

System prompt for the Campaign Calendar generator (embedded in the AI nodes of
`workflows/awareness/campaign-calendar.json`). The AI acts as an awareness
programme manager and returns a single JSON object:

```
{ year, months:[ { month, theme, focus, channels[], keyDates[], ideas[] } ] }  // 12 months
```

Themes are varied across the year to cover the major human-risk areas. `Render
HTML` builds a 12-month calendar/table **PDF** (Gotenberg) and an **`.ics`** feed
(one all-day event per month launch), both written to
`/reports/awareness/calendar/`; the PDF is returned in chat. Tailored to the
optional **Focus/region** and **Audience**.
