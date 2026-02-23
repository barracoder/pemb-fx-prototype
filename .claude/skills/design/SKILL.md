---
name: design
description: Opinionated design system for the Pemberton FX Hedging Prototype — typography, color palette, spacing, elevation, component patterns, Radzen overrides, layout rules, and animation tokens.
user-invokable: true
---

# Professional Web Design System

Use this design system when building or modifying UI in the Pemberton FX Hedging Prototype. All values are defined as CSS custom properties and must be used instead of hardcoded values.

---

## Typography

**Font family:** Inter (Google Fonts), weights 400, 500, 600.

```css
font-family:
  "Inter",
  system-ui,
  -apple-system,
  BlinkMacSystemFont,
  "Segoe UI",
  sans-serif;
```

### Type Scale

| Token class        | Size | Weight | Usage                        |
| ------------------ | ---- | ------ | ---------------------------- |
| `.page-title`      | 24px | 600    | Page headings (h3)           |
| `.section-heading` | 18px | 600    | Section dividers             |
| `.card-title`      | 15px | 500    | Card / panel headings        |
| `.body`            | 14px | 400    | Default body text            |
| `.caption`         | 12px | 500    | Labels, uppercase indicators |

**Caption convention:** `.caption` should be `text-transform: uppercase; letter-spacing: 0.05em`.

---

## Color Palette

### Brand & Accent

```css
--color-primary: #1e3a5f; /* Navy — sidebar, headings, primary buttons */
--color-accent: #0ea5e9; /* Sky blue — active states, links, highlights */
```

### Semantic Colors

```css
--color-success: #16a34a; /* Green — approved, complete */
--color-warning: #f59e0b; /* Amber — pending, caution */
--color-danger: #dc2626; /* Red — rejected, error */
--color-info: #0ea5e9; /* Same as accent */
```

### Surfaces

```css
--surface-body: #f8fafc; /* Page background */
--surface-card: #ffffff; /* Card / panel background */
--surface-sidebar: #1e293b; /* Dark sidebar */
--surface-topbar: #ffffff; /* Top bar */
--surface-hover: #f1f5f9; /* Hover background */
--surface-border: #e2e8f0; /* Dividers, borders */
```

### Category Colors (workflow diagram nodes)

```css
--category-data-input: #1565c0; /* Blue — steps 0, 1 */
--category-processing: #00796b; /* Teal — steps 2, 3 */
--category-approval: #e65100; /* Orange — steps 4, 5 */
--category-output: #2e7d32; /* Green — steps 6, 7, 8 */
```

### Text Colors

```css
--text-primary: #0f172a; /* Headings, body */
--text-secondary: #64748b; /* Subtitles, descriptions */
--text-on-dark: #f1f5f9; /* Text on dark backgrounds */
--text-on-primary: #ffffff; /* Text on primary-colored backgrounds */
```

---

## Spacing

4px base unit. Use these custom properties for all margin, padding, and gap values.

```css
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-7: 28px;
--space-8: 32px;
--space-9: 36px;
--space-10: 40px;
--space-11: 44px;
--space-12: 48px;
```

---

## Elevation

### Shadows

```css
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md:
  0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
--shadow-lg:
  0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.1);
```

### Border Radii

```css
--radius-sm: 4px;
--radius-md: 8px;
--radius-lg: 12px;
```

---

## Component Patterns

### Page Header

```html
<div class="page-header">
  <h3 class="page-title">Page Name</h3>
  <p class="page-subtitle">Brief description of the page purpose.</p>
</div>
```

```css
.page-header {
  margin-bottom: var(--space-8);
}
.page-title {
  font-size: 24px;
  font-weight: 600;
  color: var(--text-primary);
  margin: 0 0 var(--space-1) 0;
}
.page-subtitle {
  font-size: 14px;
  color: var(--text-secondary);
  margin: 0;
}
```

### Status Badge Pill

```html
<span class="status-badge status-badge--approved">Approved</span>
```

Variants: `--pending` (amber bg), `--approved` (green bg), `--rejected` (red bg).

```css
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-1) var(--space-3);
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.status-badge--pending {
  background: #fef3c7;
  color: #92400e;
}
.status-badge--approved {
  background: #dcfce7;
  color: #166534;
}
.status-badge--rejected {
  background: #fee2e2;
  color: #991b1b;
}
```

### Empty State

```html
<div class="empty-state">
  <span class="material-icons empty-state__icon">cloud_upload</span>
  <h4 class="empty-state__heading">No data uploaded</h4>
  <p class="empty-state__description">Upload a CSV file to begin.</p>
</div>
```

```css
.empty-state {
  text-align: center;
  padding: var(--space-12) var(--space-6);
  color: var(--text-secondary);
}
.empty-state__icon {
  font-size: 48px;
  margin-bottom: var(--space-4);
  opacity: 0.5;
}
.empty-state__heading {
  font-size: 15px;
  font-weight: 500;
  color: var(--text-primary);
  margin: 0 0 var(--space-2) 0;
}
.empty-state__description {
  font-size: 14px;
  margin: 0;
}
```

### Loading State

```html
<div class="loading-state">
  <div class="loading-state__spinner"></div>
  <p class="loading-state__text">Processing...</p>
</div>
```

### Data Card

```html
<div class="data-card">
  <div class="data-card__header">
    <h4 class="card-title">Title</h4>
  </div>
  <div class="data-card__body">
    <!-- Content -->
  </div>
</div>
```

```css
.data-card {
  background: var(--surface-card);
  border: 1px solid var(--surface-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
}
.data-card__header {
  padding: var(--space-4) var(--space-6);
  border-bottom: 1px solid var(--surface-border);
}
.data-card__body {
  padding: var(--space-6);
}
```

### Upload Drop Zone

```html
<div class="upload-zone">
  <span class="material-icons upload-zone__icon">cloud_upload</span>
  <p class="upload-zone__text">
    Drag & drop or <strong>browse</strong> to upload
  </p>
  <InputFile ... />
</div>
```

```css
.upload-zone {
  border: 2px dashed var(--surface-border);
  border-radius: var(--radius-md);
  padding: var(--space-8) var(--space-6);
  text-align: center;
  background: var(--surface-body);
  transition:
    border-color 0.2s ease,
    background 0.2s ease;
}
.upload-zone:hover {
  border-color: var(--color-accent);
  background: #f0f9ff;
}
.upload-zone__icon {
  font-size: 48px;
  color: var(--text-secondary);
  margin-bottom: var(--space-4);
  display: block;
}
.upload-zone__text {
  font-size: 14px;
  color: var(--text-secondary);
  margin: 0;
}
```

### Action Bar

```html
<div class="action-bar">
  <RadzenButton Text="Back" Variant="Variant.Outlined" Icon="arrow_back" />
  <RadzenButton
    Text="Next"
    ButtonStyle="ButtonStyle.Primary"
    Icon="arrow_forward"
  />
</div>
```

```css
.action-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-4) 0;
  margin-top: var(--space-6);
  border-top: 1px solid var(--surface-border);
}
```

---

## Radzen Overrides

### DataGrid

- Striped rows: `AllowAlternatingRows="true"`
- Uppercase headers: `.rz-datatable thead th { text-transform: uppercase; font-size: 12px; font-weight: 500; letter-spacing: 0.05em; }`
- Compact density: `.rz-datatable td { padding: var(--space-2) var(--space-4); }`

### Button

- Primary: `ButtonStyle="ButtonStyle.Primary"` — uses `--color-primary` background
- Accent: `ButtonStyle="ButtonStyle.Info"` — uses `--color-accent`
- Danger: `ButtonStyle="ButtonStyle.Danger"` — uses `--color-danger`
- Outlined: `Variant="Variant.Outlined"` — for secondary actions (e.g. Back)

### Steps (RadzenSteps)

- Override active step color: `.rz-steps .rz-steps-current { color: var(--color-accent); }`
- Step labels: font-size 12px, uppercase

### Badge

- Use for counts: `<RadzenBadge BadgeStyle="BadgeStyle.Info" Text="@count.ToString()" />`

---

## Layout Rules

```
┌──────────────────────────────────────────────────────┐
│  Sidebar (240px)  │  Top Bar (64px height)           │
│                   ├──────────────────────────────────│
│  - Brand area     │  Content (max-width: 1200px)     │
│  - Nav links      │  margin: 0 auto                  │
│  - Icons + text   │  padding: var(--space-6)          │
│                   │                                  │
└──────────────────────────────────────────────────────┘
```

- Sidebar width: **240px**
- Top bar height: **64px**
- Content max-width: **1200px**, centered with `margin: 0 auto`
- Content padding: `var(--space-6)` (24px)

---

## Animation

```css
/* Base transition for interactive elements */
transition: all 0.2s ease;

/* Page fade-in */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.page-enter {
  animation: fadeIn 150ms ease-out;
}
```

- Default transition duration: **0.2s**
- Maximum animation duration: **300ms**
- Page entrance: **150ms** fade-in with subtle upward slide
- Easing: `ease` for transitions, `ease-out` for entrances
