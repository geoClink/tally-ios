# Tally

A freelance time tracker for iOS, built with SwiftUI and Supabase.

## Stack

- **SwiftUI** — iOS, watchOS companion, Mac Catalyst
- **Supabase** — Auth (magic link + deep link), Postgres (sessions, clients, workspaces)
- **Swift Charts** — weekly/all-time hour charts
- **StoreKit 2** — in-app purchases (Free / Pro / Business)
- **ActivityKit** — Live Activity on lock screen and Dynamic Island
- **WidgetKit** — home screen widget (small + medium)
- **App Intents** — Siri shortcuts, Focus Mode filter
- **WatchConnectivity** — sync clients and sessions with Apple Watch

## Pricing

| Tier | Price | Features |
|---|---|---|
| Free | — | 1 client, basic timer, 7-day history |
| Tally Pro | $9.99 one-time | Unlimited clients, full history, CSV export, Watch, widgets, Siri |
| Tally Business | $4.99/month | Everything in Pro + Stripe invoicing, team workspaces |

## Project Structure

```
Tally/
  AppIntents/       Siri intents + Focus Mode filter
  Helpers/          Supabase client, notifications, CSV export, Live Activity, App Group store
  Models/           SessionModel, ClientRate, ConfigModel
  Store/            TallyStore (data layer), PurchaseManager (StoreKit)
  ViewModels/       TimerViewModel
  Views/            All SwiftUI views
  Widgets/          TallyTimerAttributes (shared with widget extension)

TallyWidgets/       Widget extension (home screen widget + Live Activity)
Tally Watch Watch App/  watchOS companion
```

## Setup

### 1. Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Copy your project URL and anon key into `Helpers/SupabaseManager.swift`
3. Enable Email (magic link) auth in the Supabase dashboard
4. Set the deep link redirect URL to `tally://auth`

**Required tables:** `profiles`, `sessions`, `config`, `workspaces`, `workspace_members`, `client_rates`

### 2. StoreKit

For local testing:
1. Open `TallyStore.storekit` in Xcode
2. Edit Scheme → Run → Options → StoreKit Configuration → `TallyStore.storekit`

For production:
1. Create products in App Store Connect with these exact IDs:
   - `name.GeorgeClinkscales.Tally.pro` (Non-Consumable, $9.99)
   - `name.GeorgeClinkscales.Tally.business.monthly` (Subscription, $4.99/mo, 7-day free trial)

### 3. App Group

Both the Tally and TallyWidgets targets use App Group `group.name.GeorgeClinkscales.Tally` to share widget data and Siri intent state.

### 4. WatchConnectivity

WatchConnectivity.framework must be added to both the Tally and Tally Watch Watch App targets (Do Not Embed).

## URL Scheme

`tally://` — used for Supabase auth deep links and widget/Live Activity tap-throughs.

## Web App

The web companion dashboard is available at:
[github.com/geoClink/tally-web](https://github.com/geoClink/tally-web)

Live at: https://tally-web-nu.vercel.app

Both apps share the same Supabase backend. See the [iOS compatibility guide](https://github.com/geoClink/tally-web/blob/main/supabase/ios-compatibility.md) for backend integration details.

## Supabase project

Americas, us-east-1 — project name: Tally
