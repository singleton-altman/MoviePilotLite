---
name: dashboard-metric-card
description: Use when dashboard metric sections or compact stats should share the CPU compact card surface. Trigger for media capacity, recent import trends, storage summaries, and other dashboard cards that should use DashboardMetricCard instead of custom glass or gradient wrappers.
---

# Dashboard Metric Card

## Overview

Use this skill when a dashboard card should adopt the same surface treatment as the compact CPU card: a restrained tile surface, adaptive border, and DashboardPalette-driven light/dark behavior.

The shared card lives in lib/modules/dashboard/widgets/dashboard_widget_styles.dart as DashboardMetricCard.

## Workflow

1. Inspect the existing metric or trend card and identify the outer decorative container only.
2. Preserve the card's data binding, headings, chart widgets, tap handlers, skeleton/loading states, and internal spacing unless the request asks for layout changes.
3. Replace manual outer card decorations, glass wrappers, BackdropFilter shells, or gradient card backgrounds with DashboardMetricCard.
4. Keep using DashboardMiniStat, DashboardProgressBar, and DashboardPalette inside the card where they already fit the content.
5. Format the touched Dart files and run static analysis for the changed files.

## Guidelines

- Use DashboardMetricCard for individual metric cards and compact stat panels, not for the whole page background.
- Prefer the default radius and padding for CPU-like compact cards. Larger summary cards may pass slightly larger padding while keeping the same surface style.
- Avoid adding one-off gradients, shadows, or blur layers around DashboardMetricCard unless the design request specifically asks for a different card hierarchy.
- If multiple dashboard cards need the same background cleanup, migrate only their outer shell first so the behavioral surface stays small.
