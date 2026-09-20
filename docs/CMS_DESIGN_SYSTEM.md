# Field Notes CMS Design System

Status: v1.0  
Authority: all `/admin` UI. New CMS UI must follow this document unless a documented exception is necessary.

## 1. Product principle

**Content is primary; CMS controls are secondary.**

The CMS is a compact editorial tool, not a marketing site. Prefer systematic reduction over decoration: fewer containers, borders, type sizes, actions, and one consistent location for each kind of control.

## 2. Information architecture

Four work domains:

| Domain | Functions | Primary UI |
| --- | --- | --- |
| Articles | create, search, filter, edit, preview, publish, unpublish, delete | DataTable + Editor |
| Article settings | slug, excerpt, tags, featured, feature image, bilingual metadata | Inspector |
| Tags | create, edit, delete, bilingual name/description | DataTable + Form |
| Site content | homepage, about, footer, bilingual values | Section navigator + Form |

System functions: authentication, sign out, view public site, save/status/error feedback.

## 3. Layouts

### Standard admin page
Use one shared `AppShell`: compact 192px desktop sidebar + content area. Every standard page uses the same `PageHeader`, content width, gutters and navigation.

### Article editor
Use a dedicated workspace with three layers:
1. application chrome / action toolbar;
2. document canvas;
3. fixed inspector.

On narrow screens the inspector becomes a drawer. Lifecycle actions must remain accessible.

## 4. Design tokens

### Spacing
`4 / 8 / 12 / 16 / 24 / 32 / 48px`

### Radius
- controls: 4px
- panels: 6px
- avoid decorative large radii

### Color
- app background: `#F5F5F2`
- panel: `#FFFFFF`
- subtle: `#FAFAF8`
- text primary: `#171717`
- text secondary: `#666666`
- text muted: `#999999`
- border: `#E5E5E2`
- primary action: near-black
- green: published/success only
- red: destructive/error only

### Typography roles
- page title: 28–32px
- document title: 36–40px
- section heading: 14px semibold
- UI body: 13px
- label: 11px medium
- metadata: 10–11px
- article body editor: serif ~18px

Avoid proliferating micro typography, uppercase labels, and letter spacing.

## 5. Core component patterns

The CMS should converge on these reusable patterns:

`AppShell`, `Sidebar`, `PageHeader`, `Toolbar`, `Button`, `IconButton`, `TextField`, `Textarea`, `Checkbox`, `SegmentedControl`, `StatusBadge`, `DataTable`, `FormSection`, `Inspector`, `EmptyState`.

Editor-specific: `DocumentCanvas`, `ContentBlock`, `BlockToolbar`, `ImageField`.

Pages must not invent independent button/input/panel systems when an existing pattern applies.

## 6. Action hierarchy

- **Primary:** one per action area; e.g. 新增文章, 發布, 儲存變更. Dark fill.
- **Secondary:** e.g. 預覽, 編輯. Border/subtle background.
- **Tertiary:** e.g. 返回, 查看網站. Text treatment.
- **Destructive:** e.g. 刪除. Red text, visually subordinate to primary actions.

## 7. Data tables

Tables are operational, not editorial. A row should answer:
**what is it → status → classification → recent activity → action**.

For articles:
- Chinese title is primary.
- English title is secondary text beneath the primary title, not a dedicated wide column.
- Prefer recently updated information over redundant date columns.
- Use restrained status dot + label.
- Whole rows may be navigable; keyboard-accessible links remain present.
- Row action affordance stays visually quiet.

## 8. Forms

Create and edit flows for the same entity use the same form pattern. Never use browser `prompt()` for CMS editing.

Field order follows task meaning, not database schema. Labels are concise. Helper text is muted. Read-only/generated values are visually distinct but remain legible.

## 9. Feedback and language

Primary CMS language is Traditional Chinese.

Canonical save states:
- `尚未儲存`
- `正在儲存…`
- `已儲存`
- `儲存失敗`

Canonical publication states:
- `草稿`
- `正在發布…`
- `已發布`
- `發布失敗`

Do not expose raw mixed-language prototype strings such as `發布ed`. Translate user-facing validation/errors where practical; technical detail may be secondary.

## 10. Responsive behavior

Desktop optimizes density and persistent context. Narrow layouts may collapse the sidebar and inspector, but must not remove capabilities. Destructive and lifecycle actions remain reachable. Tables may progressively reduce metadata before forcing horizontal scrolling.

## 11. Accessibility

- visible focus state for interactive controls;
- semantic buttons/links/labels;
- keyboard-accessible primary navigation and table destinations;
- no status communicated by color alone;
- meaningful image alt fields;
- adequate target sizes on touch layouts.

## 12. Implementation rule

`src/layouts/AdminLayout.astro` is the design-system authority for shared tokens and primitives. Page-local CSS is reserved for genuinely page-specific composition.

Normalization order:
1. AdminLayout + tokens + shared shell
2. Article list
3. Article editor
4. Tags
5. Site content
6. Login
7. Responsive audit
8. Interaction/copy/error audit
