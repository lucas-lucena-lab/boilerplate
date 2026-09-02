# Base rules (apply to all projects)

This file is loaded by Claude Code at the user level (`~/.claude/CLAUDE.md`)
and applies to every project. Project-specific rules go in each project's
own `CLAUDE.md` (which has higher precedence).

Source: adapted from "Clean Code pra Agentes de IA" by Fabio Akita
(https://akitaonrails.com/2026/04/20/clean-code-para-agentes-de-ia/).

## Code style

- Functions: 4-20 lines. Split if longer.
- Files: under 500 lines. Split by responsibility.
- One thing per function, one responsibility per module (SRP).
- Names: specific and unique. Avoid `data`, `handler`, `Manager`.
  Prefer names that return <5 grep hits in the codebase.
- Types: explicit. No `any`, no `Dict`, no untyped functions.
- No code duplication. Extract shared logic into a function/module.
- Early returns over nested ifs. Max 2 levels of indentation.
- Exception messages must include the offending value and expected shape.

## Comments

- Keep your own comments. Don't strip them on refactor — they carry
  intent and provenance.
- Write WHY, not WHAT. Skip `// increment counter` above `i++`.
- Docstrings on public functions: intent + one usage example.
- Reference issue numbers / commit SHAs when a line exists because
  of a specific bug or upstream constraint.

## Code review comments

- When I ask you to post comments on a code review (PR review comments,
  replies on review threads, or a summary before resolving a thread),
  do not use dash punctuation in the comment text. No em dash (—),
  no en dash (–), and no hyphen used as a sentence separator or bullet
  marker. Use separate sentences, commas, parentheses, or a colon
  instead. Hyphens inside real compound words or identifiers
  (`well-known`, `utf-8`, `x-forwarded-for`) are fine.
- Say what was actually done for each finding. A resolved thread with
  no explanation is not useful to a reviewer.
- Report the final state from the source (GitHub), do not assume a
  post succeeded. Retry server errors and confirm the result.

## Tests

- Tests run with a single command (define it in the project's CLAUDE.md).
- Every new function gets a test. Bug fixes get a regression test.
- Mock external I/O (API, DB, filesystem) with named fake classes,
  not inline stubs.
- Tests must be F.I.R.S.T: fast, independent, repeatable,
  self-validating, timely.

## Dependencies

- Inject dependencies through constructor/parameter, not global/import.
- Wrap third-party libs behind a thin interface owned by this project.

## Structure

- Follow the framework's convention (Rails, Django, Next.js, etc.).
- Prefer small focused modules over god files.
- Predictable paths: controller/model/view, src/lib/test, etc.

## Formatting

- Use the language default formatter (`cargo fmt`, `gofmt`, `prettier`,
  `black`, `rubocop -A`). Don't discuss style beyond that.

## Logging

- Structured JSON when logging for debugging / observability.
- Plain text only for user-facing CLI output.

## Defensive code

- Implement circuit breaker, retry with backoff, timeout, and graceful
  degradation only when this file or the project's CLAUDE.md lists the
  failure modes that need them. Don't add defensive code speculatively.
