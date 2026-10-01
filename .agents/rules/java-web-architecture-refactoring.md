# Rule: Java Web Application WebContent / docBase Simplification

When refactoring or modernizing a Java JSP/Servlet web application that uses nested web roots (`WebContent/` or `webapp/`) with root forwarders:

1. **Audit Phase**:
   - Trace all form actions, redirects (`sendRedirect`), dispatchers (`getRequestDispatcher`), AJAX/fetch endpoints, and `<a href>` links.
   - Catalog all forwarder/shim files and their inbound/outbound references.

2. **WEB-INF Consolidation**:
   - Ensure the nested `WEB-INF` has all necessary TLDs (`/WEB-INF/tld/*.tld`) required by `<%@ taglib uri="/WEB-INF/tld/..." %>` directives before deleting the root `WEB-INF`.
   - Synchronize `<welcome-file-list>` in `web.xml` to include canonical welcome files (e.g., `index.jsp`).
   - Compile all Java sources directly into the target `WEB-INF/classes/` directory.

3. **Routing Simplification**:
   - Replace any hard-coded `/WebContent/` or conditional path prefixes with direct `request.getContextPath() + "/..."`.
   - Use relative redirects (e.g., `safeRedirect(response, "../index.jsp")`) or context-aware paths (`ctx + "/actions/..."`) directly.

4. **Safety & Verification**:
   - Search the entire repository for remaining references to the nested root folder before and after removing shims.
   - Verify that all compile-time and runtime JAR dependencies (`mysql-connector`, `jakarta.mail`, `jstl`) reside in the single target `WEB-INF/lib/`.
