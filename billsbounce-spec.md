# Project Specification: Bill's Bounce (billsbounce.com)

## Multi-Tenant White-Label Inflatable Rental SaaS with Geofenced Territory Exclusivity

### 1. Executive Summary & Context

`billsbounce.com` is a mobile-first web app and PWA built for an inflatable rental business.

- **Territory Exclusivity:** Implements a geofenced exclusivity feature licensing software to exactly _one operator per county_. If a competitor tries to sign up inside an active boundary, they are hard-blocked.

### 2. Tech Stack & Architecture

- **Backend:** ASP.NET Core 9 Web API (Clean Architecture).
- **Database:** PostgreSQL with PostGIS extensions via `NetTopologySuite`.
- **Frontend:** Next.js 15 PWA (App Router) with Tailwind CSS.
