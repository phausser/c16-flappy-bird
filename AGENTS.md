# Repository instructions

## Commit messages

Always use Conventional Commits (semantic Git format):

`type(scope): description`

The scope is optional. Use a suitable type such as `feat`, `fix`, `refactor`,
`perf`, `docs`, `test`, `build`, `ci` or `chore`. Keep the description concise
and describe the actual change. Mark breaking changes with `!` and explain
them in a `BREAKING CHANGE:` footer.

Examples:

- `fix(render): prevent score update flicker`
- `perf(hud): redraw only the blinking title`
- `refactor(font): extract glyph definitions`
- `docs: update implementation status`
