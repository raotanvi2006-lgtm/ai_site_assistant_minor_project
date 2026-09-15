# AI Site Intelligence Assistant
### A 6-Week Project — Mobile App + Open-Source LLM for Construction Site Progress

> **Two learning outcomes drive everything here:**
> **(1) build a real Flutter mobile app**, and **(2) use + deploy open-source LLMs**.
> Every week's work maps to one or both. IoT and academic paperwork are intentionally out of scope.

---

## 1. Problem Statement

Your father runs a civil engineering practice with **multiple construction projects going at once** and
**several workers under him**. Right now everything lives in scattered WhatsApp chats — voice notes,
photos, forwarded documents. To answer a simple question ("how much cement did Site B use last week?"
or "is the plinth done at the Kalyan site?") he has to scroll through chats and piece it together
manually. This wastes time and means:

- No structured, searchable record of daily progress across sites
- Cost/timeline slippage caught late
- Land documents, contracts, and bills that can't be searched
- No single place to see what's happening across all projects

## 2. Solution — What You're Building

A mobile app + AI backend where **workers send updates in whatever form is natural** — text, voice note,
photo, or document — and an **open-source LLM acts as the brain** that reads all of it, extracts the
useful facts, and keeps a live dashboard updated automatically. On top of that:

1. **Multi-modal intake** — text, audio (Hindi/Marathi/English), images, PDFs/docs from the field
2. **Speech-to-text** on voice notes, then **LLM extraction** of structured data (work done, materials, labour, issues)
3. **Auto-updated dashboard** — no manual data entry by your father
4. **RAG document Q&A** — ask questions over contracts, land records, and past updates in plain language

Everything runs on **free, open-source models** — no paid APIs, no recurring cost.

---

## 3. The Two Core Outcomes (what you'll actually learn)

### Outcome A — Mobile App Development (Flutter/Dart)
You'll build a real **two-sided app**, not a toy:
- **Worker view:** record voice note, snap/upload photo, upload a document, or type an update; pick a project.
- **Owner view (your father):** dashboard with project list, progress %, cost/material charts, and a chat to ask questions.
- Core Flutter skills exercised: widgets, `StatelessWidget` vs `StatefulWidget`, the widget tree, themes,
  external packages, async/`Future`, HTTP + multipart upload, state management, and charts.

### Outcome B — Using + Deploying Open-Source LLMs
You'll run the **full practical lifecycle** of open models:
- **Run locally** with Ollama (quantized models on a normal laptop, no GPU needed).
- **Use hosted open models** via OpenRouter's free tier.
- **Build a fallback wrapper** that tries hosted first, falls back to local automatically.
- **Structured extraction** (free-form text/speech → clean JSON) via prompting.
- **RAG** — embeddings + a vector DB so the model answers from *your* documents, not its training data.
- **Deploy** the whole thing in a container so it runs reliably and reproducibly.

---

## 4. System Architecture

```
                     ┌──────────────────────── FLUTTER APP ────────────────────────┐
                     │  Worker view: text / voice / photo / document upload         │
                     │  Owner view: dashboard, cost/progress charts,                │
                     │              RAG chat ("ask about any site")                 │
                     └───────────────────────────┬─────────────────────────────────┘
                                                  │  REST (HTTPS)
                                                  ▼
        ┌──────────────────────────── FastAPI BACKEND (Python) ───────────────────────────┐
        │                                                                                   │
        │  Ingest ──► Whisper (speech-to-text) ──► LLM extract ──► structured JSON          │
        │                                              │                                    │
        │  Model client: OpenRouter (default)  ◄──────►│  local Ollama (fallback)           │
        │                                              │                                    │
        │  RAG: docs ──► chunk ──► embed (nomic) ──► ChromaDB ──► retrieve ──► LLM answer    │
        └───────────┬──────────────────────────────┬──────────────────────────────────────┘
                    ▼                                ▼
              ┌───────────┐                   ┌───────────┐
              │  MongoDB  │                   │ ChromaDB  │
              │ (updates, │                   │ (document │
              │  costs)   │                   │  vectors) │
              └───────────┘                   └───────────┘
```

---

## 5. Tech Stack (100% Free)

| Layer | Tool / Model | Purpose |
|---|---|---|
| Model runtime (default) | **OpenRouter** free tier | Hosted access to open models, no credit card |
| Model runtime (fallback) | **Ollama** | Runs a local model with an OpenAI-compatible API — offline / rate-limit fallback |
| Language model | **NVIDIA Nemotron Nano** (or current free equivalent) | Structured extraction + RAG answers |
| Speech-to-text | **OpenAI Whisper** (`tiny`/`base`) | Transcribes Hindi/Marathi/English voice notes |
| STT Indic boost (optional) | **AI4Bharat IndicWav2Vec** | Better Hindi/Marathi accuracy if needed |
| Embeddings | **nomic-embed-text** (via Ollama) | Turns documents into vectors for retrieval |
| Vector DB | **ChromaDB** | Stores document embeddings for RAG |
| Structured DB | **MongoDB** (Community / Atlas free tier) | Site updates, costs, material logs |
| Backend | **FastAPI** (Python) + **LangChain/LlamaIndex** | Glues transcription → extraction → storage → RAG |
| Mobile app | **Flutter** + **Dart** | Worker field app + owner dashboard |
| Charts | **fl_chart** (Flutter) | Cost trends, timelines, progress |
| Containerization | **Docker** + **Docker Compose** | Reproducible deployment of the model backend + DBs |
| Hosting | **GitHub** + **Render/Railway** free tier | Code + optional live demo link |

### Deployment Strategy: OpenRouter Default, Local Fallback

**OpenRouter's free tier is the default path** for all LLM calls. But a free hosted API has real limits
worth designing around: **rate limits** (~20 req/min + daily cap), **model rotation** (free lineup
changes), **needs internet** (construction sites often have patchy connectivity), and **no uptime SLA**.

**The fix:** keep a **local model via Ollama as an automatic fallback**. If OpenRouter is rate-limited,
offline, or the model is rotated out, the backend silently switches to the local copy instead of erroring.
This "graceful degradation" is exactly the kind of real-world reasoning that makes you good at *deploying*
open-source models — not just calling an API. Keep the local model small and quantized so it runs on a
laptop without a dedicated GPU.

---

## 6. The 6-Week Build Plan

**You start with mobile app development.** Flutter UI can be built and run against **mock data** before any
backend exists — so Weeks 1–2 give you a working, clickable app first (motivating, visible progress). Then
Weeks 3–4 build the open-source LLM backend, Week 5 wires the app to it and deploys the models, and Week 6
is real data + demo. Each week has a concrete deliverable you can actually run.

> **Why this order works:** a Flutter app talks to the backend over a simple REST contract. If you define
> that contract (the JSON shapes) up front in Week 1, you can build the entire app against a fake/mock data
> layer, then swap in the real backend in Week 5 by changing one service class — no UI rewrite.

### Week 1 — Flutter Fundamentals + App Shell (mock data)
**Goal:** learn Flutter and get a clickable app running on your phone.
- Work through Flutter basics: widgets, `StatelessWidget` vs `StatefulWidget`, the widget tree, hot reload, themes, packages.
- Scaffold the app: navigation, a shared theme, and a **worker view** and **owner view** split.
- Define the **REST contract** (the JSON shapes for updates, projects, dashboard) and build a **mock data service** that returns hard-coded sample data.
- **Deliverable:** app runs on your phone/emulator, you can navigate both views with realistic mock data.

### Week 2 — Finish the Mobile App (still on mock data)
**Goal:** build out all the real screens so the app is feature-complete on the front end.
- **Worker view:** project picker + intake screen to record a voice note, snap/upload a photo, upload a document, or type an update. Handle mic/storage permissions and show upload progress/confirmation.
- **Owner view:** project list, per-project progress %, cost/material charts (`fl_chart`), recent-updates feed, and a **RAG chat screen** (answers stubbed for now).
- Add state management (Provider/Riverpod), loading/error/empty states, and a clean theme.
- **Deliverable:** full two-sided app, visually complete and interactive, running entirely on the mock service.

### Week 3 — Open-Source LLM Foundations + Structured Extraction
**Goal:** get comfortable running open models and turn free-form text into clean JSON.
- Sign up for **OpenRouter**; install **Ollama** and pull a small quantized model — run it locally to see it work.
- Learn the **OpenAI-compatible API shape** shared by both (so one code path serves both).
- Build the **model-client wrapper:** try OpenRouter first, fall back to local Ollama on failure/timeout.
- First real task: typed progress update → LLM → **structured JSON** (work done, materials + qty, labour, issues).
- Practice prompt design for reliable JSON (schemas, examples, validation/retry).
- **Deliverable:** a script where you paste a messy update and get back validated structured JSON, from either model.

### Week 4 — Speech-to-Text, RAG & Backend API
**Goal:** handle voice + documents and stand up the API your app already expects.
- Set up **Whisper**; transcribe real voice notes (record a few in Hindi/Marathi to test accuracy). Pipe transcript → extraction.
- Build **RAG:** chunk contracts/land docs → embed with `nomic-embed-text` → store in **ChromaDB** → retrieval-augmented Q&A.
- Design the **MongoDB schema:** `projects`, `updates`, `workers`, `expenses`, `documents`.
- Wrap it in a **FastAPI** backend implementing the exact REST contract from Week 1 (ingest text/audio/image/doc, RAG query, dashboard data).
- **Deliverable:** POST a voice note → transcribed, structured, stored; ask a question about an uploaded PDF → grounded answer.

### Week 5 — Wire the App to the Backend + Deploy the Models
**Goal:** connect the two halves and make the LLM backend reproducible and resilient.
- **Swap the mock service for the real API** in the Flutter app — because the contract matched, this is mostly one service class. Handle real multipart uploads for audio/images.
- **Dockerize** the backend; write **Docker Compose** for backend + MongoDB + ChromaDB (+ Ollama service).
- Understand and document **quantization** and model sizing (why a 4B model runs on your laptop).
- Prove the **OpenRouter → Ollama fallback** by killing internet mid-request — this is your headline demo.
- **Deliverable:** full two-sided app doing complete round-trips against the deployed backend; working offline-fallback demo.

### Week 6 — Real Data, Polish & Demo
**Goal:** validate end-to-end and package it.
- End-to-end test with **real data** from an actual site (best possible demo material).
- Polish: cross-site comparison, cost-overrun flags, empty/error states, small UX fixes.
- Record a **demo video** and write a short README explaining the architecture and model choices.
- **Deliverable:** working system + demo video + README.

> **Buffer reality check:** if a week slips, protect Weeks 1–2 (the app) and Weeks 3–4 (LLM pipeline). The
> mock data layer means the app stays demoable on its own even if the backend runs late.

---

## 7. How This Nails *Your* Two Goals

- **Mobile app development:** you start here — two full weeks (Weeks 1–2) building a real two-sided Flutter
  app with uploads, charts, and chat against a mock data layer, then wiring it to the live backend in Week 5.
  You'll come out able to build and ship a Flutter app.
- **Using + deploying open-source LLMs:** you run models locally, use hosted open models, build a fallback
  wrapper, do structured extraction and RAG, and containerize/deploy the whole backend. That's the complete
  practical skillset employers mean by "works with open-source LLMs."

---

## 8. Why This Differentiates Your Resume

- Solves a **real problem for a real business** (your father's) — a concrete, memorable interview story.
- Uses **self-hosted open-source models**, not a thin wrapper over a paid API — real system design.
- Voice-note-to-structured-data is a genuine **ML/NLP** challenge, not just prompt-response.
- Combines **a polished Flutter app + open-source LLM deployment** — the exact two skills you set out to learn.

**Suggested resume line:**
> "Built a construction site progress tracker: a Flutter app where workers submit text/voice/photo/document
> updates, and an open-source LLM (NVIDIA Nemotron via OpenRouter with automatic local Ollama fallback)
> transcribes, extracts structured data, and answers document queries via RAG — stored in MongoDB and
> deployed with Docker, with zero recurring API cost."

---

## 9. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Laptop too weak for local LLM | Use OpenRouter as default; keep the local model small + quantized for fallback only |
| Whisper Hindi/Marathi accuracy | Fall back to IndicWav2Vec; also let workers type/correct if needed |
| OpenRouter rate limits / model rotation | Automatic Ollama fallback (already core to the design) |
| Flutter learning curve eats time | It's front-loaded into Weeks 1–2 with mock data, so the curve is behind you before backend work begins |
| App and backend drift apart | Define the REST contract in Week 1 and build the app against it — the backend just implements the same shapes in Week 4 |
| Scope creep | Protect Weeks 1–4 (app + LLM pipeline); treat the vision model and predictive analytics as stretch goals |

## 10. Stretch Goals (only if ahead of schedule)

- **Vision model** (Moondream / small Qwen-VL via Ollama) for rough construction-stage estimate from photos.
- **Text-to-speech** so the dashboard can read summaries back to your father.
- **Predictive analytics** — forecast cost/timeline overrun from historical trends.
