# Stable Build Summary

Date: 2026-04-21

## Outcome

Application flow is now stable for root deployment under Tomcat `webapps` and supports resume-friendly testing without restarting from scratch.

## Main Fixes Applied

1. Added root compatibility routing for JSP pages.
2. Added root compatibility routing for `/actions/...` handlers.
3. Added root `WEB-INF/web.xml` with welcome-file support.
4. Replaced direct `response.sendRedirect(...)` in workflow-critical action JSPs with safe header-based redirects.
5. Fixed JSP compile-time unreachable-code issues in action handlers.
6. Synced required runtime libraries into root `WEB-INF/lib`.
7. Restored reliable complaint submission with optional image upload (stable non-multipart submission path + base64 image persistence).

## Known Deployment Requirement

Deploy project with root structure intact (including root `WEB-INF` and root `actions` shims), not only the `WebContent` folder.

## Known Runtime Quirk

On some Tomcat setups, opening the app context root without a trailing slash can return 500:

- `http://localhost:8081/advjavaproject` may fail in environments with customized context-root redirect behavior.
- `http://localhost:8081/advjavaproject/` and `http://localhost:8081/advjavaproject/index.jsp` are the stable entry URLs.

This does not indicate a broken user workflow if the page-level routes return 200.

## Verified User Journey

1. User login and OTP flow works.
2. Complaint registration works.
3. Complaint appears in dashboard table.
4. Dashboard resume flow works after redeploy + refresh.

## Recommendation for Future Changes

1. Keep route compatibility shims unless deployment model is unified.
2. Run `SMOKE_TEST_CHECKLIST.md` after every redeploy.
3. Apply same safe redirect helper pattern for any new JSP action endpoints.
