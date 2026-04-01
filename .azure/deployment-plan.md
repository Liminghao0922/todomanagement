# Deployment Plan

Status: Implemented

## Request

Modify the web application so frontend API calls are proxied through the web Container App to the backend API Container App, because the backend ingress is internal.

## Workspace Mode

- Mode: MODIFY
- Scope: Existing Vue/Vite frontend container runtime and related configuration/docs
- Non-goals: No resource deletion, no API application logic changes, no changes to the user's existing API internal ingress decision

## Current State

- The frontend already prefers same-origin `/api` when `VITE_API_BASE_URL` is empty or `/api`.
- Local development uses the Vite dev-server proxy.
- Production web container currently serves static files with `serve` only, so `/api` is not handled at runtime.
- The backend Container App is configured as internal-only in infrastructure.

## Proposed Changes

1. Replace the web runtime static server with a reverse-proxy-capable web server.
2. Serve the built SPA and proxy `/api/*` requests from the web container to the internal API Container App.
3. Keep local development behavior unchanged via the existing Vite proxy.
4. Adjust the frontend Docker image and runtime config so the proxy target is configurable through environment variables.
5. Update the relevant docs/examples to reflect that Azure production should use same-origin `/api` plus runtime proxy, not a public API URL.

## Expected Files

- `src/web/Dockerfile`
- `src/web/...` runtime proxy config files to be added as needed
- `src/web/src/api/http.ts` only if minor normalization is needed
- Documentation files that currently instruct setting a public `API_BASE_URL`

## Validation

- Build the web app container assets successfully.
- Verify lint/build does not break from the change.
- Confirm frontend requests still target `/api` in production.

## Risks

- If the proxy target is misconfigured, all API calls will fail at runtime.
- Existing deployment docs currently assume a public API URL and will become misleading unless updated.

## Approval

Approved and implemented.