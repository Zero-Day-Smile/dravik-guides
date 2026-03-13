# Dravik Feature Gap Audit (Flutter Legacy vs New Website Frontend)

This file lists features that exist in the existing Flutter frontend (`lib/screens`, `lib/services`) but are not implemented in the current React website frontend (`website/src`).

## Present in Website Frontend

- Auth (sign in, sign up, forgot password)
- Destination discovery with category/difficulty/search filters
- Destination detail pages with ratings/reviews and save toggle
- User dashboard (profile summary, saved destinations, trips list)
- Trip planner page (create trips, status updates, delete trips, destination prefill)
- Weather forecast page (live 7-day forecast for destinations with coordinates)
- Country explorer page (country/continent destination aggregation and filtering)
- Static guide content page
- Guide detail page with markdown-style rendering (`/guides/:slug`)
- Operational safety center baseline (local emergency contacts, check-ins, SOS simulation logs)
- Analytics dashboard baseline (`/analytics`) with trip/saved/country insights
- Emergency guides library baseline (`/emergency-guides`) with searchable response playbooks
- Activity tracker baseline (`/activity`) with session logging, streak days, and distance estimates
- Interactive map baseline (`/map`) with destination markers and POI popups
- Marketing/landing sections (hero, interactive sections, CTA)

## Missing From Website (Compared to Existing Flutter Frontend)

### Navigation/Experience Features

- Platform-aware edition banner system (`edition_banner`, `edition_banner_for_screen`)
- Platform capability gating (`platform_capabilities`, `feature_flags`, `edition_copy`)
- Full multi-screen app navigation parity (21+ Flutter screens)

### Map & Geo Features

- Advanced interactive map parity: partial (web Leaflet map baseline implemented)
- Offline map tile caching and offline region management
- Trail/POI overpass-powered map data workflows

### Trip & Planning Features

- Dedicated trip planner screen parity: partial (baseline web planner implemented, advanced itinerary parity still pending)
- Trip detail editor parity from mobile app
- Rich route planning and day-by-day trek planning tools

### Gear & Checklist Features

- Full gear module parity (`gear_screen`, `gear_screen_new`, checklist detail)
- Pro gear features from `gear_service_pro`
- Advanced checklist editing flows

### Weather Features

- 7-day forecast parity: partial (live forecast page implemented; advanced alert logic pending)
- Weather alert service behavior parity
- Offline weather predictions/cached weather features

### Guides & Content Features

- Ultimate guide library parity (`ultimate_guide_screen`)
- Emergency guides screen parity: partial (web emergency guide library implemented)
- Markdown guide detail reading experience parity: partial (web detail route + markdown-style content rendering implemented)
- Offline guides caching support

### Safety & Emergency Features

- Emergency contacts operational workflow parity: partial (web local CRUD + check-ins implemented)
- SOS/alert behavior from `emergency_contact_service`: partial (web SOS simulation/logging implemented)
- Trip safety analyzer parity: partial (risk scoring, factors, and recommendations integrated into trip planner)

### Activity/Tracking/Analytics Features

- Activity tracker parity: partial (web session tracker baseline implemented; no live GPS)
- Analytics dashboard parity with mission metrics and achievements: partial (web dashboard + mission progress cards implemented)
- Mission engine UI/logic parity (`mission_engine/*`, mission widgets)

### Mobile-Only Features Not Ported to Website

- AR trail scanner variants (`ar_trail_scanner_*`)
- Group sync (`group_sync_screen`, `group_sync_service`)
- Offline regions manager (`offline_regions_screen`)
- Sensor-driven features (compass/location adapters)
- Device integrations: camera, bluetooth, vibration, battery, secure local auth

## Backend/Data Gaps

- Website uses its own Supabase schema in `website/supabase/migrations/*` and does not yet map all Flutter service tables/flows.
- No parity layer yet for Flutter service contracts such as place guide assistant and mission-oriented telemetry flows.

## Performance Notes

- Current web bundle remains large (>1 MB main chunk). Next step should include route-based code splitting/lazy loading.

## Recommendation

Use this list as the implementation backlog to reach full parity while keeping website scope web-first and mobile-only capabilities intentionally excluded or represented as web-friendly alternatives.
