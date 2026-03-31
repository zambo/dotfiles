; ─── Keys ────────────────────────────────────────────────────────────────────
; Config item keys (e.g. DATABASE_URL, PORT)
(config_item key: (key) @variable.member)

; ─── Export keyword ───────────────────────────────────────────────────────────
(export_keyword) @keyword

; ─── Values ───────────────────────────────────────────────────────────────────
; Quoted strings (all quote styles)
(quoted_string) @string
(multiline_string) @string

; Known boolean literals (must come before the generic @string rule)
; Note: #match? uses Vim regex syntax, so use \| for alternation, not |
((unquoted_string) @boolean
  (#match? @boolean "^true$\|^false$"))

; undefined literal
((unquoted_string) @constant.builtin
  (#match? @constant.builtin "^undefined$"))

; Numeric literals (integer or decimal, Vim regex: \. for literal dot, \? for optional)
((unquoted_string) @number
  (#match? @number "^-\?[0-9]\+\(\.[0-9]\+\)\?$"))

; Default: unquoted values are strings
(unquoted_string) @string

; ─── Operators ────────────────────────────────────────────────────────────────
"=" @operator

; ─── Comments ─────────────────────────────────────────────────────────────────
; Plain comments — ordinary text
(plain_comment) @comment

; Dividers (# --- or # ===) — visually distinct from plain comments
(divider) @comment.special

; ─── Decorator Comments ───────────────────────────────────────────────────────
; All decorator comment lines are opaque tokens; sub-parts are highlighted via
; mini.hipatterns in the Neovim plugin config (see treesitter-envspec.lua).
; The whole line gets @comment coloring as the base.
(decorator_comment) @comment

; ─── String Escape Sequences ─────────────────────────────────────────────────
(escape_sequence) @string.escape

; ─── String Expansion ─────────────────────────────────────────────────────────
; Variable names inside $VAR or ${VAR} expansions
(expansion name: (identifier) @variable)

; Fallback expansions ${VAR:-default} — ":-" signals a fallback value
((expansion) @string
  (#match? @string ":-"))
