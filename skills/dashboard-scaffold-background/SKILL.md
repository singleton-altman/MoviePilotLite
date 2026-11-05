---
name: dashboard-scaffold-background
description: Use when Flutter pages should reuse the Dashboard scaffold shell, adaptive background, user background image overlay, or transparent app bar treatment. Trigger for More, Search, tab pages, and dashboard-like pages whose local background gradients should be replaced by the shared DashboardScaffold.
---

# Dashboard Scaffold Background

## Overview

Use this skill when a Flutter page should share the Dashboard page shell and background behavior instead of defining its own page-level Scaffold background, glow layers, or light/dark gradient stack.

The shared implementation lives in lib/widgets/dashboard_scaffold.dart and is backed by DashboardPalette plus AppService user background settings.

## Workflow

1. Inspect the target page root layout before editing. Preserve the page's controller, scroll controller, refresh behavior, slivers, navigation, and content structure.
2. Replace the page-level Scaffold with DashboardScaffold when the page needs the Dashboard background and transparent app bar behavior.
3. Pass the existing PreferredSizeWidget app bar into DashboardScaffold when the page already owns a top navigation bar.
4. Keep inner CustomScrollView, ListView, RefreshIndicator, and ConstrainedPageContent structure intact unless the task explicitly asks for layout changes.
5. Remove local full-page background widgets, radial glow-only decorations, hard-coded page background colors, and duplicate extendBodyBehindAppBar setup after DashboardScaffold is in place.
6. Ensure content top padding still accounts for transparent navigation bars. Pages with a standard app bar usually need status bar height plus toolbar height before the first list item.

## Guidelines

- Use DashboardScaffold for page-level shell reuse, not for small cards or nested content.
- Use DashboardPageBackground directly only when a page already has a custom Scaffold that cannot be replaced safely.
- Leave app bars transparent so the shared background remains visible behind navigation chrome.
- Prefer DashboardPalette for any remaining page-level colors so light and dark mode stay coherent.
- Do not reintroduce separate page background gradients or decorative glow stacks after adopting the shared scaffold.
