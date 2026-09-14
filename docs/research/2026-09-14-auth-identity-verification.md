# Auth and identity verification for D09 as of 2026-09-14

This is disposable research, not product code. It lives only under `docs/research/` and is never imported by, copied into, or linked from product code, per `.claude/rules/23-research.md`.

**Question:** What do current, authoritative sources say about (1) SurrealDB's authentication/authorisation model and (2) the OAuth/OS-credential/workload-identity building blocks that D09 (identity, security, audit) is likely to rely on, so that D09 can cite verified facts rather than assumption?

**Method:** Read in docs. Web search and WebFetch against official SurrealDB docs, the IETF datatracker, and vendor/CNCF documentation on 2026-09-14. Nothing here was verified by running SurrealDB or any code — no SurrealDB instance was started and no OAuth flow was executed. Anything that reads as behaviour rather than a documented statement is a paraphrase of docs, not an observation. D02/D08 must still verify SurrealDB behaviour experimentally before relying on it for the data model or query layer.

## 1. SurrealDB 3.x authentication and authorisation model

**Finding**

- Four levels of user/identity exist: **root** (instance-wide), **namespace**, **database** (all "system users" created with `DEFINE USER`, operating under built-in roles `OWNER`, `EDITOR`, `VIEWER`), and **record users** — application users that are rows in a table, defined via `DEFINE ACCESS ... TYPE RECORD` with `SIGNUP`/`SIGNIN` clauses, with no implicit permissions beyond what table/field `PERMISSIONS` grant. System users are not subject to table `PERMISSIONS`; they follow RBAC instead.
- `DEFINE ACCESS` is the general mechanism for authentication methods (introduced in 2.x, see below) and supports three types: **JWT** (trust tokens signed by a configured issuer), **RECORD** (custom signup/signin logic producing a session as a record user, positioning SurrealDB as a "web database"), and **BEARER** (revocable, auditable bearer grants tied to a system or record user, meant for service-to-service or long-lived programmatic access).
- Table `PERMISSIONS` clauses (`DEFINE TABLE ... PERMISSIONS FOR select|create|update|delete WHERE ...`) are SurrealQL expressions evaluated against the authenticated session, chiefly through the `$auth` variable (e.g. `$auth.id`, arbitrary custom fields such as `$auth.admin`). Default is `PERMISSIONS NONE` (deny all) unless stated; `PERMISSIONS FULL` allows all four operations. A `FOR select` clause must not itself write data. This is SurrealDB's row-level-security primitive.
- Session state after authentication includes `$session` (connection metadata: IP, ns, db, authenticated record id), `$token` (JWT claims: `iat`, `nbf`, `exp`, `jti`, `iss`), and `$auth` (fields of the authenticated record/user).
- Session duration and token duration are independent and both configurable via `DURATION FOR SESSION` / `DURATION FOR TOKEN` (and `FOR GRANT` for bearer grants) on `DEFINE USER` / `DEFINE ACCESS`. Default session duration is unlimited (`NONE`); default token duration is one hour. A short-lived token can sit inside a much longer-lived session, with re-authentication via `signin`/`authenticate`.
- The docs do not explicitly prescribe whether a backend service should connect as one privileged system user versus per-end-user record users — both are architecturally supported (root/ns/db user with app-level authorization logic in the service, or record-user sessions per end user relying on `PERMISSIONS`). This is a design choice, not a documented convention — see Implications below.
- **2.x → 3.x change relevant here**: `DEFINE SCOPE` and the old `DEFINE TOKEN ... ON SCOPE` (1.x-era) were replaced by `DEFINE ACCESS ... TYPE RECORD` starting in 2.0, folding token definitions into the access statement. Also as of 2.x, authentication is **enabled by default**; the pre-2.x unauthenticated default now requires an explicit `--unauthenticated` flag. Multi-tenancy (isolated namespace/database per tenant) is described as introduced "in 3.0."
- A relevant, currently-open vulnerability: **CVE-2026-63735** (CVSS 8.6, CWE-639 Authorization Bypass Through User-Controlled Key) — SurrealDB versions before 3.2.0 failed to validate namespace/database scope inside custom API routes, letting an authenticated caller (valid credentials in *some* namespace/database) reach a custom API endpoint in a *different* tenant's namespace/database by specifying it in the URL path. Fixed in 3.2.0. This is directly relevant to any multi-tenant design that relies on namespace/database boundaries for isolation and that also exposes SurrealDB's custom API routes.

**Sources (checked 2026-09-14)**

- https://surrealdb.com/docs/surrealdb/security/authentication
- https://surrealdb.com/docs/surrealql/statements/define/access
- https://surrealdb.com/docs/surrealql/statements/define/table
- https://surrealdb.com/docs/build/migrating/from-old-surrealdb-versions/1x-to-2x
- https://surrealdb.com/docs/surrealql/statements/define/access/record
- https://surrealdb.com/docs/languages/rust/concepts/multi-tenancy
- https://www.vulncheck.com/advisories/surrealdb-before-authentication-bypass-via-custom-api
- https://advisories.gitlab.com/cargo/surrealdb/CVE-2026-63735/ (CVE detail: affected <3.2.0, fixed 3.2.0)

## 2. Per-request identity propagation for multi-tenant row-level security

**Finding**

- SurrealDB's model is that `PERMISSIONS` are enforced by the query engine itself on every query, live query subscription, and API call, evaluated against `$auth`/`$session` for the current authenticated connection/session — there is, per the docs summarised, no separate authorization service to call before the database call.
- Per-connection sessions carry the identity; SDK docs (Java example cited) show multiple independent sessions multiplexed over one physical connection, each with its own namespace/database/auth context — i.e. per-request identity is carried at the session level, and one physical connection can serve several logically distinct sessions.
- **Documented caveat found**: multi-tenancy via namespace/database isolation is a boundary the engine is supposed to enforce, but CVE-2026-63735 (above) shows a concrete case where an unrelated feature (custom API routes) bypassed that boundary for authenticated-but-wrong-tenant callers. This means namespace/database isolation and table `PERMISSIONS`/`$auth` row-level security are necessary but were not, at least once, jointly sufficient — the security guarantee depends on every feature surface correctly checking the caller's namespace/database scope, not just the permissions engine.
- No other explicit "documented caveats/limits" of `$auth`-based row-level security for multi-tenant use (e.g. formal guarantees around session/connection pooling not leaking `$auth` context across requests) were found in the official docs pages read. This should be treated as an **unverified area**, not a confirmed absence of caveats — it needs an experiment (D02/D08) rather than a doc citation.

**Sources (checked 2026-09-14)**

- https://surrealdb.com/docs/learn/security/authorization/permissions-and-row-level-security
- https://surrealdb.com/docs/reference/java/concepts/multiple-sessions
- https://advisories.gitlab.com/cargo/surrealdb/CVE-2026-63735/

## 3. OAuth 2.0 Device Authorization Grant

**Finding**

- Confirmed: **RFC 8628**, "OAuth 2.0 Device Authorization Grant," Proposed Standard, published August 2019.
- Intended for "Internet-connected devices that either lack a browser ... or are input constrained" such that typing credentials directly is impractical — explicitly the profile a CLI or headless agent fits.
- Flow: (1) device requests a device code from the authorization server using its client id; (2) server returns a `device_code`, a short `user_code`, and a `verification_uri` plus expiry; (3) device displays the `user_code`/URI to the user; (4) user opens the URI on a separate, capable device (phone/laptop), authenticates, enters the code, and approves/denies; (5) meanwhile the device polls the token endpoint with the `device_code`; (6) on approval the server issues an access token, otherwise an error or `authorization_pending`.

**Source (checked 2026-09-14):** https://datatracker.ietf.org/doc/html/rfc8628

## 4. Token exchange, refresh-token rotation / OAuth Security BCP, DPoP, PKCE, OAuth 2.1

**Finding**

- **RFC 8693**, "OAuth 2.0 Token Exchange," Proposed Standard, published January 2020. Defines how a client presents an existing token to an authorization server acting as a Security Token Service to obtain a new token, supporting impersonation and delegation — relevant to any "agent acts on behalf of a user" or service-to-service delegation pattern.
- **OAuth 2.0 Security Best Current Practice** is no longer a draft: it was published as **RFC 9700** (**BCP 240**) in January 2025, "Best Current Practice for OAuth 2.0 Security," updating/extending RFC 6749, RFC 6750 and RFC 6819. As of 2026-09-14 there is a further in-progress Internet-Draft, `draft-ietf-oauth-security-topics-update`, proposing additional updates on top of RFC 9700 — not yet an RFC. RFC 9700 is the current citable BCP; refresh-token rotation guidance (rotate refresh tokens on use, detect reuse, bind/sender-constrain where possible) lives in RFC 9700's text per the search summary, but the note author did not fetch RFC 9700's full body directly (only a search-engine summary) — **treat the specific refresh-token-rotation wording as needing a direct read of RFC 9700 before quoting it in D09**.
- **DPoP**: confirmed as **RFC 9449**, "OAuth 2.0 Demonstrating Proof of Possession," Proposed Standard, September 2023. Sender-constrains access/refresh tokens to a client-held key pair via a signed `DPoP` header, defending against token replay/theft — the current standard mechanism for sender-constrained tokens referenced by the Security BCP.
- **PKCE**: confirmed as **RFC 7636**, "Proof Key for Code Exchange by OAuth Public Clients," Proposed Standard, September 2015. `S256` is the mandatory-to-implement challenge method; `plain` exists only for constrained back-compat cases.
- **OAuth 2.1**: as of 2026-09-14 this is still an Internet-Draft, currently `draft-ietf-oauth-v2-1-16`, active in the OAuth working group, with IESG submission targeted for December 2026 per the working group's own milestone — **it is not yet an RFC**. The draft makes PKCE (`code_challenge`, `S256`) required for the authorization code grant rather than optional, folding what was BCP advice in OAuth 2.0 into a hard requirement.

**Sources (checked 2026-09-14)**

- https://datatracker.ietf.org/doc/html/rfc8693
- https://datatracker.ietf.org/doc/rfc9700/ and https://datatracker.ietf.org/doc/html/rfc9700
- https://datatracker.ietf.org/doc/draft-ietf-oauth-security-topics-update/ (in-progress update, not yet RFC)
- https://datatracker.ietf.org/doc/html/rfc9449
- https://datatracker.ietf.org/doc/html/rfc7636
- https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/ (draft-ietf-oauth-v2-1-16, not yet RFC)

## 5. Storing CLI credentials on disk

**Finding**

- Consistent, credible convention across the tools/vendors sampled (Heroku CLI, Zowe CLI, and several OSS credential-storage libraries): prefer the OS-native secure store — **macOS Keychain** (via the Security framework, or `security` CLI as fallback), **Windows Credential Manager** (native binding, or PowerShell as fallback), and on Linux the **freedesktop Secret Service API** (via `libsecret`/`secret-tool`, backed by GNOME Keyring or KDE Wallet depending on desktop environment).
- **Headless caveat, explicitly confirmed**: on Linux, Secret Service depends on a running keyring daemon tied to a logged-in desktop session (D-Bus session bus). Headless servers, containers, and CI runners typically have no such session, so Secret Service is unavailable there. The documented fallback pattern is a credential file with restrictive permissions (mode `0600`), and/or delegating to the CI/CD platform's own secret store (e.g. GitHub Actions secrets, Jenkins credentials) injected as environment variables rather than a keyring. Zowe CLI's docs are the clearest single vendor source for "configuring secure credential storage on headless Linux."
- No single canonical, vendor-neutral standards document (e.g. an RFC or OWASP page specifically titled for CLI credential storage) was found; this is convention from practitioner/vendor docs rather than a formal standard. OWASP's general secrets-management guidance was not directly fetched in this pass — flagged as a gap if D09 wants an OWASP-specific citation.

**Sources (checked 2026-09-14)**

- https://docs.zowe.org/v3.2.x/user-guide/cli-configure-scs-on-headless-linux-os/
- https://www.heroku.com/blog/securing-heroku-cli-credentials-with-system-keychain-storage/
- (aggregate search summary only, not individually fetched: GitHub `davidnussio/envsec`, `magarcia/cross-keychain` — cited here as illustrative of common practice, not as an authoritative standard)

**Gap:** no OWASP page was directly verified for this question; do not cite OWASP for this point in D09 without fetching a specific OWASP URL first.

## 6. Convention for agent/workload identity

**Finding**

- **SPIFFE/SPIRE** is the closest thing to a settled, vendor-neutral convention: SPIFFE is a graduated CNCF specification defining a workload identity primitive (the SPIFFE ID) and short-lived credential formats (X.509-SVID, JWT-SVID); SPIRE is the reference runtime that attests workloads (based on platform/OS facts, no shared bootstrap secret) and issues/rotates those credentials automatically.
- SPIRE also exposes an **OIDC Federation** endpoint, letting it act as an OIDC issuer that major clouds trust — a workload can exchange a JWT-SVID for a short-lived cloud credential (AWS STS via Web Identity Federation, GCP Workload Identity Federation service-account impersonation, Azure AD Workload Identity Federation) without any static long-lived secret. Microsoft's own docs describe federating a SPIFFE/SPIRE identity into Entra Workload ID, which is a concrete example of a major vendor treating SPIFFE as an interoperable input rather than a competing scheme.
- For a self-hosted service like task-tree-stream, this suggests two credible options if/when "agent identity" needs to be more than a bearer API key: (a) run/embed SPIRE as an internal workload-identity issuer and have the backend and any long-running agent processes authenticate to it by platform attestation, or (b) imitate the pattern at a much smaller scale — short-lived, automatically-rotated, cryptographically-bound credentials issued per agent/workload, without necessarily adopting the full SPIFFE/SPIRE stack. Both are legitimate; which one fits our scale and self-hosting constraints is a design decision, not a fact — flagged in Implications.

**Sources (checked 2026-09-14)**

- https://spiffe.io/docs/latest/spire-about/spire-concepts/
- https://spiffe.io/docs/latest/keyless/oidc-federation-aws/
- https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-spiffe-spire
- https://spiffe.io/docs/latest/keyless/vault/readme/

## Implications for design (for D09 to consider — not decided here)

- **Design decision, not a fact**: whether the backend connects to SurrealDB as a single privileged system user (application enforces per-tenant/per-user authorization itself) or as per-end-user record-user sessions relying on SurrealDB's own `PERMISSIONS`/`$auth` row-level security (database enforces it). SurrealDB supports both; nothing in the docs recommends one for a service like ours. This should be an explicit D09 decision, and CVE-2026-63735 is a reason to not treat SurrealDB's own tenant boundary as sufficient in isolation regardless of which model is picked — defence in depth (application-level checks even when the DB also enforces `PERMISSIONS`) looks warranted.
- **Design decision, not a fact**: pin an exact SurrealDB version at or above 3.2.0 (the CVE-2026-63735 fix) once D02 settles the version, and track that this is a security-relevant reason for the floor, not just a features reason.
- The device authorization grant (RFC 8628) is a strong, standards-based fit for "log in the CLI/agent from a terminal with no local browser" — matches the vision's CLI/agent-facing client. This is confirmed as fact; adopting it is still a D09 decision.
- If the design wants delegated/impersonated access (an agent acting as a specific user, or a service exchanging a session token for a narrower-scoped one), RFC 8693 token exchange is the standards-track mechanism to evaluate — a design decision, not decided here.
- RFC 9700 (OAuth Security BCP) and RFC 9449 (DPoP) together are the current authoritative basis for "how should refresh tokens and access tokens be protected" — D09 should read RFC 9700's full text directly (not just this note's search-derived summary) before writing specific rotation/detection requirements.
- CLI credential storage: OS keychain first, `0600` file as the documented fallback, with an explicit note that headless Linux (servers, containers, CI) commonly has no Secret Service session available — the client/skill design must not assume a keychain is always reachable. Which exact fallback (file vs. delegating to CI secret stores vs. something else) is a design decision.
- Full SPIFFE/SPIRE adoption is very possibly heavier than this project needs at its current scale; imitating the pattern (short-lived, rotated, attested-or-provisioned credentials per agent/workload) without the full stack is a lighter-weight option worth listing as an alternative in D09. This choice is explicitly left open here.
