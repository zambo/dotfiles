/**
 * Tree-sitter grammar for the @env-spec dotenv superset format.
 *
 * Translated from packages/env-spec-parser/grammar.peggy.
 *
 * Architecture decisions:
 *
 * 1. Comment classification: All comment line types are terminal tokens.
 *    Tree-sitter lexes terminals before structurals, so we must encode the
 *    "starts with @decoratorName" distinction at the regex level.
 *    Sub-token highlighting (decorator name, value, etc.) is done in
 *    highlights.scm using #match? predicates — a standard tree-sitter pattern.
 *
 * 2. String expansion ($VAR, ${VAR}, ${VAR:-default}, $(cmd)) is grammar-level.
 *    The Peggy parser handles expansion post-parse; here it's a CST node.
 *
 * 3. CRLF line endings accepted (tree-sitter receives raw bytes; Peggy normalizes).
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const NEWLINE = /\r?\n/;

module.exports = grammar({
  name: "envspec",

  extras: ($) => [/[ \t]/],

  conflicts: ($) => [
    // When parsing "KEY= # @dec", the post_comment field is ambiguous:
    // it could be a post_comment or the start of the next comment_block.
    // We declare this conflict so tree-sitter resolves it via GLR.
    [$.config_item],
  ],

  rules: {
    // ─── Root ─────────────────────────────────────────────────────────────────
    source_file: ($) =>
      repeat(
        choice(
          $.config_item,
          $.divider,
          $.comment_block,
          $.blank_line,
        ),
      ),

    // A blank line is an empty line (just a newline). We use a distinct regex
    // so the lexer doesn't confuse it with the NEWLINE inside config_item.
    blank_line: (_) => /\r?\n/,

    // ─── Config Item ──────────────────────────────────────────────────────────
    // config_item does NOT include pre-comments. Comments preceding an item
    // are always parsed as standalone comment_block nodes at the source_file level.
    // The semantic relationship (comment attached to next item) is not expressed
    // in the CST — it's handled at the query/tool level.
    config_item: ($) =>
      seq(
        optional($.export_keyword),
        field("key", $.key),
        "=",
        optional(field("value", $._value)),
        optional(field("post_comment", $._comment_line)),
        NEWLINE,
      ),

    export_keyword: (_) => token(seq("export", /[ \t]+/)),
    key: (_) => /[a-zA-Z_][a-zA-Z0-9_.\-]*/,

    // ─── Comment Lines ────────────────────────────────────────────────────────
    // All are terminal tokens. Priority: divider(3) > decorator/ignored(2) > plain(1).
    _comment_line: ($) =>
      choice(
        $.decorator_comment,
        $.ignored_decorator_comment,
        $.plain_comment,
      ),

    // Decorator comment: # optional-space @letter-starting-name ...
    // The ENTIRE line is one token so the lexer can classify it correctly.
    // highlights.scm uses #match? to highlight sub-parts.
    //
    // Pattern explanation:
    //   # optional-space @name (= value | (args))? (space @name...)* optional-trailing-comment
    //
    // We match the whole line broadly as: # spaces @letter non-newline*
    // This is enough for correct classification; fine-grained sub-highlighting
    // is handled in queries/highlights.scm.
    decorator_comment: (_) =>
      token(
        prec(
          2,
          seq(
            "#",
            /[ \t]*/,
            /@[a-zA-Z][^\r\n]*/,
          ),
        ),
      ),

    // JSDoc-style: @name: text  or  @name <space> text-not-starting-with-@/#
    // These are a subset of what decorator_comment would match, so we need
    // higher or equal precedence. We rely on tree-sitter trying longer matches
    // first: ignored patterns are more specific (have colon or space+non-special).
    // In practice, since decorator_comment matches greedily, we handle JSDoc
    // patterns as a sub-type in the highlight queries, not as a separate token.
    // We keep this rule for semantic clarity — it's matched as a decorator_comment
    // at the token level, and queries filter it by regex.
    //
    // NOTE: ignored_decorator_comment is NOT used as a separate lexer token here.
    // Instead we use #match? in highlights.scm to detect these patterns.
    // The rule is kept as an alias for documentation/future use.
    ignored_decorator_comment: (_) =>
      token(
        prec(
          2,
          seq(
            "#",
            /[ \t]*/,
            choice(
              seq(/@[a-zA-Z][a-zA-Z0-9_]*:/, /[^\r\n]*/),
              seq(/@[a-zA-Z][a-zA-Z0-9_]*/, /[ \t]+[^@#\r\n][^\r\n]*/),
            ),
          ),
        ),
      ),

    // Plain comment: everything that doesn't start with @letter after #spaces.
    // Regex: # spaces (non-@ char | @ non-letter | nothing)
    plain_comment: (_) =>
      token(
        prec(
          1,
          seq(
            "#",
            /[ \t]*([^@\r\n][^\r\n]*|@[^a-zA-Z\r\n][^\r\n]*)?/,
          ),
        ),
      ),

    post_comment_text: (_) => token(seq("#", /[^\r\n]*/)),

    // ─── Divider ──────────────────────────────────────────────────────────────
    // # --- or # === or # ### (3+ of: - = * #)
    // Must have higher priority than any comment token.
    divider: (_) =>
      token(
        prec(
          3,
          seq("#", /[ \t]*/, /[-=*#]{3,}/, /[^\r\n]*/),
        ),
      ),

    // ─── Comment Block ────────────────────────────────────────────────────────
    comment_block: ($) =>
      prec.left(repeat1(seq(field("line", $._comment_line), NEWLINE))),

    // ─── Values ───────────────────────────────────────────────────────────────
    // Note: function_call is NOT a separate alternative here. Without an external
    // scanner, tree-sitter cannot distinguish "identifier(args)" from an unquoted
    // string because the terminal regex for unquoted_string matches greedily.
    // Function-call-like values are parsed as unquoted_string and highlighted
    // via #match? predicates in highlights.scm.
    _value: ($) =>
      choice(
        $.multiline_string,
        $.quoted_string,
        $.unquoted_string,
      ),

    // Unquoted string: cannot start with quote char, cannot contain #.
    // Tree-sitter cannot express PEG-style ordered choice for terminals, so
    // we use a GLR conflict between function_call and unquoted_string, letting
    // the parser choose function_call when the value is followed by "(".
    unquoted_string: ($) =>
      seq(
        /[^'"`#\r\n ][^#\r\n]*/,
        repeat($.expansion),
      ),

    unquoted_string_nospace: (_) => /[^'"`# \t\r\n]+/,

    // ─── Quoted Strings ───────────────────────────────────────────────────────
    quoted_string: ($) =>
      choice(
        $.double_quoted_string,
        $.single_quoted_string,
        $.backtick_quoted_string,
      ),

    double_quoted_string: ($) =>
      seq(
        '"',
        repeat(
          choice(
            $.escape_sequence,
            $.expansion,
            token.immediate(/[^"\\$\r\n]+/),
          ),
        ),
        '"',
      ),

    single_quoted_string: ($) =>
      seq(
        "'",
        repeat(choice($.escape_sequence, token.immediate(/[^'\\\r\n]+/))),
        "'",
      ),

    backtick_quoted_string: ($) =>
      seq(
        "`",
        repeat(
          choice(
            $.escape_sequence,
            $.expansion,
            token.immediate(/[^`\\$\r\n]+/),
          ),
        ),
        "`",
      ),

    escape_sequence: (_) => token.immediate(seq("\\", /[^\r\n]/)),

    // ─── Multiline Strings ────────────────────────────────────────────────────
    multiline_string: ($) =>
      choice(
        $.triple_backtick_string,
        $.triple_double_quoted_string,
        $.multiline_double_quoted_string,
        $.multiline_single_quoted_string,
      ),

    triple_backtick_string: (_) =>
      token(
        prec(
          1,
          seq("```", repeat(choice(/[^`]/, /`[^`]/, /``[^`]/)), "```"),
        ),
      ),

    triple_double_quoted_string: (_) =>
      token(
        prec(
          1,
          seq('"""', repeat(choice(/[^"]/, /\"[^"]/, /\"\"[^"]/)), '"""'),
        ),
      ),

    multiline_double_quoted_string: (_) =>
      token(
        seq('"', /[^"\r\n]*/, repeat1(seq(/\r?\n/, /[^"\r\n]*/)), '"'),
      ),

    multiline_single_quoted_string: (_) =>
      token(
        seq("'", /[^'\r\n]*/, repeat1(seq(/\r?\n/, /[^'\r\n]*/)), "'"),
      ),

    // ─── String Expansion ─────────────────────────────────────────────────────
    expansion: ($) =>
      choice(
        seq(
          "${",
          field("name", $.identifier),
          optional(seq(":-", field("fallback", /[^}]+/))),
          "}",
        ),
        seq("$(", field("command", /[^)]+/), ")"),
        seq(token.immediate("$"), field("name", $.identifier)),
      ),

    identifier: (_) => /[a-zA-Z_][a-zA-Z0-9_]*/,

    // ─── Decorators ───────────────────────────────────────────────────────────
    // NOTE: decorators are NOT parsed as grammar nodes because decorator_comment
    // is a terminal token (the entire line). Decorator sub-structure is expressed
    // in highlights.scm via #match? regex predicates on the comment text.
    //
    // However, we keep decorator nodes for potential future use with an external
    // scanner, or for inline post-value decorator comments.
    // For now they are unused in the main grammar flow.

    // ─── Function Calls ───────────────────────────────────────────────────────
    function_call: ($) =>
      seq(
        field("name", $.function_name),
        field("args", $.fn_args),
      ),

    function_name: (_) => /[a-zA-Z][a-zA-Z0-9_]*/,

    fn_args: ($) =>
      seq(
        "(",
        optional(
          seq(
            $._fn_arg,
            repeat(seq(",", $._fn_arg)),
            optional(","),
          ),
        ),
        ")",
      ),

    _fn_arg: ($) =>
      choice(
        $.key_value_pair,
        $.function_call,
        $.quoted_string,
        $.unquoted_fn_arg,
      ),

    key_value_pair: ($) =>
      seq(
        field("key", /[a-zA-Z][a-zA-Z0-9_]*/),
        "=",
        field(
          "value",
          choice($.quoted_string, $.unquoted_fn_arg, $.function_call),
        ),
      ),

    unquoted_fn_arg: (_) => /[^ \t\r\n,)]+/,
  },
});
