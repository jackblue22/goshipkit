---
name: GoShipKit
version: 0.1
status: accepted
surfaces:
  - responsive-web
  - flutter-mobile
  - wails-desktop
accessibility: WCAG 2.2 AA
---

# GoShipKit design contract

GoShipKit should feel calm, capable, and understandable to a small team and its
stakeholders. It combines the information precision of a modern project tool
with the warmth of a collaborative workspace. It must not look like a developer
console, an enterprise administration suite, or a generic gradient-heavy AI
dashboard.

## Experience principles

1. **The work is the interface.** Projects, tasks, milestones, updates, and
   feedback dominate the screen; decorative chrome stays quiet.
2. **Plain language first.** Use familiar nouns and actions. Introduce Scrum or
   Git terminology only when the related optional feature is enabled.
3. **Private state is visible.** Draft/internal/published status is always
   legible near the content and never communicated by color alone.
4. **Progress is explainable.** Show the completed and eligible task counts near
   percentages. Never imply effort, productivity, or individual performance.
5. **One system, native adaptations.** Share tokens, hierarchy, terminology, and
   behavior across clients while respecting browser, desktop, iOS, and Android
   interaction conventions.
6. **Density follows the audience.** Member workspaces may be compact; mentor,
   client, and investor views use calmer layouts and plain-language summaries.

## Visual direction

The design takes inspiration from Linear's precision and Notion's approachable
workspace tone without reproducing either brand. GoShipKit's identity uses a
maritime teal signal against neutral, slightly cool surfaces. Borders and space
establish hierarchy; shadows are reserved for overlays and floating surfaces.

Avoid purple-blue hero gradients, glass panels without functional meaning,
excessive rounded cards, emoji icons, oversized marketing typography inside the
product, and animation on routine task operations.

## Color tokens

All component colors must reference semantic tokens. Raw hex values belong only
in token definitions.

| Role | Light | Dark | Use |
|---|---|---|---|
| Canvas | `#F7F8FA` | `#11171A` | App background |
| Surface | `#FFFFFF` | `#182126` | Primary panels |
| Surface raised | `#F1F4F7` | `#202B31` | Hover, selected, nested areas |
| Text | `#17202A` | `#F2F5F7` | Primary content |
| Text muted | `#52606D` | `#A8B3BA` | Secondary content |
| Border | `#D8DEE6` | `#344148` | Dividers and boundaries |
| Primary | `#0F6B73` | `#5FC4CC` | Primary action and active navigation |
| On primary | `#FFFFFF` | `#082F34` | Content on primary |
| Focus | `#175CD3` | `#84ADFF` | Keyboard focus ring |
| Success | `#18794E` | `#5CCB91` | Completed/on track |
| Warning | `#9A6700` | `#F0B429` | At risk/due soon |
| Danger | `#B42318` | `#FF8A80` | Destructive/off track |
| Info | `#175CD3` | `#84ADFF` | Informational state |

Validate actual foreground/background pairs to WCAG contrast targets. Status
components also include an icon or text label.

## Typography

- Use the platform/system sans-serif stack by default so self-hosted installs do
  not depend on a font CDN.
- Product title: 28–32 px, 700 weight, compact line height.
- Page title: 22–24 px, 650–700 weight.
- Section title: 16–18 px, 600 weight.
- Body: 15–16 px, 400–500 weight, 1.45–1.6 line height.
- Supporting text: 13–14 px; never below 12 px.
- Use monospace only for task keys, commit hashes, versions, and technical IDs.
- Prefer sentence case. Do not use all caps for ordinary navigation or buttons.

## Spacing, shape, and elevation

- Base spacing unit: 4 px; common steps: `4, 8, 12, 16, 24, 32, 48`.
- Controls: minimum 40 px on pointer-first surfaces and 44 px on touch surfaces.
- Radius: 6 px for controls, 10 px for panels, 14 px for dialogs. Pills are for
  tags/status only.
- Use one-pixel borders for grouping. Avoid card-inside-card nesting unless it
  represents real hierarchy.
- Only menus, dialogs, drag previews, and sticky overlays receive elevation.

## Responsive layout

Design from narrow to wide and validate at approximately 375, 768, 1024, and
1440 px. Breakpoints respond to content pressure rather than device names.

- Narrow: one content column, bottom or compact top navigation, full-width
  sheets, no hover-only actions.
- Medium: collapsible navigation, board horizontal scrolling with clear column
  boundaries, optional split detail view.
- Wide: persistent 232–256 px sidebar, fluid work area, optional 320–400 px
  inspector. Avoid arbitrary centered max-width on boards and data tables.
- Fixed navigation must reserve content space and respect mobile safe areas.
- Preserve filters, selection, scroll position, and draft input across layout
  changes and back navigation.

## Platform adaptations

### Responsive web

The web client is the reference implementation. It supports keyboard navigation,
deep links, browser history, responsive pointer/touch behavior, and visible
focus. Dense tables collapse into prioritized rows or detail sheets rather than
shrinking every column.

### Wails desktop

Reuse React components and tokens from `packages/ui`. Add desktop affordances
only where useful: command shortcuts, native window chrome integration, file
pickers, notifications, and contextual menus. Do not fork product behavior or
create a desktop-only backend.

### Flutter mobile

Reimplement the same semantics with native Flutter widgets; do not pixel-copy
the desktop layout. Use platform back behavior, safe areas, adaptive navigation,
44–48 px touch targets, text scaling, screen-reader semantics, and restoration
of navigation state. Top-level mobile navigation contains at most five items.

## Core component rules

- Every interactive component defines default, hover where applicable, focus,
  pressed, selected, disabled, loading, validation, and error states.
- Buttons use one primary action per region. Destructive actions require a clear
  label and confirmation proportional to recoverability.
- Forms keep visible labels, descriptions, and errors adjacent to fields.
  Preserve entered values after validation failure.
- Task cards show key, title, status, priority only when meaningful, assignee,
  and due state. Secondary metadata stays out of the primary scan path.
- Board columns show name and count with a clear empty drop target. Dragging has
  a keyboard alternative and never becomes the only way to change status.
- Progress includes numerator, denominator, formula help, and an empty state
  when no eligible tasks exist.
- Stakeholder content visibly identifies audience and publication state before
  the publish action is confirmed.
- Empty states explain what is absent, why it matters, and one useful next step.

## Motion

- Routine state changes use CSS/native transitions around 120–220 ms.
- Animate opacity and transforms; avoid layout-thrashing width/height animation.
- Motion communicates relationship, status, or spatial continuity. It is not a
  reward for every click.
- GSAP is reserved for justified multi-step sequences, timeline visualization,
  or a restrained public/onboarding experience on web and desktop.
- All motion has a useful static end state and respects reduced-motion settings.
  No core workflow depends on scroll-triggered animation.

## Content and localization

- Use direct, calm language: “Publish update”, not “Unleash your progress”.
- Buttons describe outcomes; errors explain recovery without blaming the user.
- Never expose secrets, internal IDs, or provider diagnostics in stakeholder UI.
- Layouts accommodate English and Vietnamese expansion without truncating
  controls or encoding meaning in word length.
- Dates render in the viewer's locale/time zone; stored values remain UTC.

## Accessibility and quality gates

- WCAG 2.2 AA contrast, keyboard operation, visible focus, semantic structure,
  accessible names, and appropriate live-region announcements are mandatory.
- Color is never the only status signal. Charts provide labels or tabular data.
- Test 200% zoom, long translated text, empty/loading/error/offline states, and
  reduced motion.
- Visually verify changed screens on representative narrow and wide viewports.
- Verify Flutter with text scaling and both major mobile platform conventions.
- Prefer measured usability and rendered evidence over aesthetic assumptions.

## Reference policy

External `DESIGN.md` catalogs may inspire a direction but are not copied into
the repository unchanged. Extract applicable principles, re-author tokens for
GoShipKit, verify accessibility, and retain GoShipKit's identity and product
boundary.
