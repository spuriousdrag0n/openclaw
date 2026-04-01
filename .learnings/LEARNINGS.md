## [LRN-20250331-001] knowledge_gap

**Logged**: 2025-03-31T09:35:00+02:00
**Priority**: high
**Status**: pending
**Area**: infra

### Summary
wttr.in geocoding failed — "Beirut" resolved to Kaiserslautern, Germany instead of Beirut, Lebanon.

### Details
Query `curl wttr.in/Beirut` returned weather for Kaiserslautern (lat 49.44, lon 7.77) rather than Beirut, Lebanon (lat 33.89, lon 35.50). JSON response confirmed `nearest_area` = Kaiserslautern. This is a wttr.in API geocoding issue, not user error.

### Suggested Action
- Use explicit coordinates for Beirut: `wttr.in/33.89,35.50`
- Or use alternative weather source (Open-Meteo) for location-sensitive queries
- Document this geocoding unreliability in TOOLS.md

### Metadata
- Source: user_feedback
- Related Files: weather skill
- Tags: wttr.in, geocoding, api-limitation
- Pattern-Key: weather.geocoding_fallback

---
