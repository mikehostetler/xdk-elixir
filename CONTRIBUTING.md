# Contributing to XDK Elixir

This SDK is **auto-generated**. The source of truth lives in the Rust code generator, not in this repository.

## How to Contribute

### Fixing bugs in the generated code

If you find a bug in the generated output (e.g., wrong function signatures, missing parameters, incorrect URL paths):

1. File an issue on [mikehostetler/xdk](https://github.com/mikehostetler/xdk) describing the problem
2. The fix should be made in the Jinja2 templates at `xdk-gen/templates/elixir/`
3. After the template fix, the SDK is regenerated and the output is copied here

### Fixing bugs in non-generated code

Files like `README.md`, `CHANGELOG.md`, `LICENSE`, and CI configuration are maintained directly in this repo. PRs for these are welcome.

### Adding new features

New features (e.g., pagination helpers, retry logic, new auth methods) should be added as templates in the generator so that they're preserved across regenerations.

## Local Development

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Run integration tests (requires .env with API credentials)
mix test --include integration
```

## Regenerating the SDK

```bash
cd /path/to/xdk
cargo run -- elixir --latest true
cp -r xdk/elixir/lib xdk/elixir/test xdk/elixir/mix.exs /path/to/xdk-elixir/
cd /path/to/xdk-elixir && mix deps.get && mix test
```
