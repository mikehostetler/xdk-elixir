# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-07

### Added

- Initial release of auto-generated X API v2 client
- Full coverage of X API v2 endpoints (Users, Posts, Lists, Spaces, Communities, DMs, etc.)
- Bearer token (OAuth 2.0 App-Only) authentication
- OAuth 1.0a user-context authentication via OAuther
- Cursor-based pagination helper (`Xdk.Paginator`)
- NDJSON streaming support (`Xdk.Streaming`)
- Structured error handling via Splode (`Xdk.Errors`)
- Rate limit error detection with retry-after calculation
- Query parameter encoding with CSV list support
