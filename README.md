# wedotv CMS OTT — Technical Assessment 🎬

Hey, welcome to the entry point of this project. This orchestrator repo is the only thing you need to clone — everything else gets pulled automatically from here. One command, and you're up and running.

| Repo | Link |
|---|---|
| 🔧 Backend | <https://github.com/rosmis/ott_back> |
| 🖥️ Frontend | <https://github.com/rosmis/ott_front> |

---

## 🔑 Test Credentials

| Role | Email | Password |
|---|---|---|
| Admin | `admin@example.com` | `password` |
| Editor | `editor@example.com` | `password` |

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed on your machine:

- [Docker](https://www.docker.com/) + Docker Compose
- [Node.js](https://nodejs.org/) (v20+)
- [Make](https://www.gnu.org/software/make/)
- Git

### Installation

```bash
git clone https://github.com/rosmis/ott_orchestrator.git
cd ott_orchestrator
make clone-all
```

That's it. The `clone-all` command will:

1. Clone both `ott_back` and `ott_front` repos into the orchestrator directory
2. Copy `.env.example` → `.env` for each
3. Build and start the Docker container for the backend (FrankenPHP)
4. Install frontend dependencies and start the Nuxt dev server

> **Backend** is available at `http://localhost:80`
> **Frontend** is available at `http://localhost:3000` (default Nuxt port)

> ⚠️ The first startup might take a minute — `composer install` runs inside the container on first boot, then migrations and seeders run automatically.

---

## 🏛️ Architecture Overview

This project deliberately follows a **decoupled API-first architecture**: a dedicated Laravel backend exposing a RESTful JSON API, and a dedicated Nuxt frontend consuming it. Two separate repositories, two separate concerns.

```
ott_orchestrator/       ← you are here (Docker + Makefile)
├── wedotv_ott_back/    ← Laravel 13 API
└── wedotv_ott_front/   ← Nuxt 4 frontend
```

---

## ⚙️ Backend Stack — `wedotv_ott_back`

| Layer | Choice |
|---|---|
| Runtime | PHP 8.3 |
| Framework | Laravel 13 |
| HTTP Server | FrankenPHP (via `dunglas/frankenphp`) |
| Database | SQLite |
| Auth | Laravel Sanctum |
| Query builder | `sylarele/http-query-config` |
| Media metadata (duration extraction) | `james-heinrich/getid3` |
| Code style | PHP CS Fixer |
| Testing | PHPUnit 12 |

### Why FrankenPHP instead of Laravel Sail?

The brief specified Laravel Sail, but I made a deliberate call to go with **FrankenPHP** instead — and here's the honest reasoning behind it.

Sail is essentially a wrapper around a heavily opinionated Docker Compose stack that comes with MySQL, Redis, Mailpit, Meilisearch and other services pre-configured. For a scoped technical assessment with a SQLite database and no background job or search requirements, that's a lot of unnecessary surface area. It pulls multiple large images, takes time to build, and frankly gets in the way of reviewing what actually matters: the code.

FrankenPHP on the other hand is a single-image, production-grade PHP application server built on top of Caddy. It handles HTTP serving, HTTPS, and PHP execution in one binary, with a minimal footprint. It's what we use in production at my current company, so it's the stack I can move the fastest with and be the most confident about.

The trade-off: not following the spec to the letter. The gain: a cleaner, faster setup that better reflects real-world production constraints.

### Why Policies over Gates?

Authorization is handled via **Laravel Policies** (`VideoPolicy`). Policies are model-scoped — the `update` and `delete` logic lives directly next to the model it protects, auto-discovered by Laravel, and slots cleanly into `$this->authorize()`. Gates are better suited for global, context-free checks; the moment you're branching on a specific model instance and user ownership, Policies are the right abstraction.

### Why `sylarele/http-query-config`?

This is an open-source HTTP query builder package that we've developed and battle-tested internally over the past few years. You'll notice it in `VideoQuery.php` — it lets you declaratively define which filters, scopes, and sorts an endpoint accepts, with built-in validation and type transformation for each parameter.

Compared to alternatives like Spatie's query builder, the key advantage for us has always been **unified syntax between the frontend and the backend**. Both sides speak the same query string contract — the backend defines it, the frontend reads it. No custom parsing, no ambiguity, no drift over time. For a project where a dedicated frontend talks directly to a Laravel API, that kind of consistency is worth a lot.

### Code structure

The backend follows a layered architecture that separates HTTP concerns from business logic:

- **Controllers** — thin, only handle request/response
- **Form Requests** — validation
- **Actions** — single-responsibility business operations (`SaveVideoAction`, `UpdateOrCreateVideoAction`)
- **DTOs** — typed data transfer between layers
- **Services** — orchestration of actions
- **Queries** — declarative, reusable query builders via `http-query-config`
- **Resources** — consistent JSON output via Laravel API Resources
- **Policies** — authorization rules
- **Enums** — `UserRole`, `VideoStatus` — no magic strings

---

## 🖥️ Frontend Stack — `wedotv_ott_front`

| Layer | Choice |
|---|---|
| Framework | Nuxt 4 (Vue 3) |
| UI components | Nuxt UI v4 (Tailwind CSS v4) |
| Auth | `nuxt-auth-sanctum` |
| Validation | `@reglejs` + Zod schemas |
| Icons | Lucide + Simple Icons (via Iconify) |
| Type safety | TypeScript + `vue-tsc` |
| Linting | ESLint (`@nuxt/eslint`) |

### Why Nuxt instead of Inertia + Vue/React or Blade + Livewire?

The brief offered the choice between Inertia (Vue/React) or Blade + Livewire. I went with **Nuxt as a standalone frontend** instead, and that deserves an explanation.

Both Inertia and Blade/Livewire keep the frontend tightly coupled to Laravel — they share the same process, the same routing layer, the same deployment. That works well for smaller monoliths, but in my experience it ages poorly. As the codebase grows, the boundary between backend and frontend logic gets blurry. Templating mixed with business logic, server-side rendering mixed with client interactivity, frontend developers stepping on backend developers' toes and vice versa. What starts as "convenient" becomes "legacy" faster than you'd expect.

A dedicated Nuxt frontend with a pure JSON API backend respects the **Single Responsibility Principle** at an architectural level. Each application has one job. The backend knows nothing about how its data gets rendered. The frontend knows nothing about database schemas. You can swap one without touching the other. You can scale them independently. You can have different teams own them independently.

It's a stack I'm very comfortable with, and one that I think reflects how modern, maintainable applications should be structured — especially for a product like an OTT platform that will likely have multiple frontends (web, mobile, TV apps) consuming the same API over time.

### Why `@regle` for validation?

`@regle` is a Vue 3-native validation library that plays very well with Zod schemas. Combined with typed schema definitions, it gives you inline, per-field, reactive validation without waiting for a form submission. Every field validates as the user types, errors appear exactly where they're relevant, and the schema doubles as both runtime validation and TypeScript type inference. It's a much cleaner experience than manual `ref`-based error tracking.

---

## 🤖 AI Usage

AI tools (GitHub Copilot) was used as a productivity aid:

- **Frontend UI scaffolding** — Used to bootstrap repetitive component structure (forms, lists, empty states). Output was reviewed and adjusted to match the actual design intent and Nuxt 4 conventions.
- **Backend unit test coverage** — Used to help cover edge cases in `VideoServiceTest` and `VideoControllerTest`, particularly around authorization boundaries and status transition assertions. All generated assertions were verified against the actual implementation before committing.
- **Policy vs Gate documentation** — Used to quickly get up to speed on the current Laravel recommendations around the Policy/Gate distinction, as our internal codebase at work abstracts over both with a custom layer. Reviewed against the official docs and adjusted to fit the actual use case.

Every line in this submission is something I can explain in a follow-up call.

---

## 🧪 Running Tests

Tests run inside the backend Docker container:

```bash
docker compose exec web php artisan test
```

---

## ⏱️ Approximate Time Spent

~10–12 hours across 2 days.

---
