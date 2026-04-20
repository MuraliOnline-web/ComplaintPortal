# Smoke Test Checklist (Tomcat Redeploy)

Use this checklist after each redeploy to verify the app quickly without restarting full debugging.

## 1. Startup and Entry

1. Open `http://localhost:8081/advjavaproject/`.
2. Confirm it lands on the app homepage (not Tomcat default page).
3. Open `http://localhost:8081/advjavaproject/index.jsp` directly and confirm no 404/500.
4. If `http://localhost:8081/advjavaproject` (without trailing slash) returns 500, continue using the trailing-slash URL and verify app pages still load successfully.

## 2. Authentication

1. Open `http://localhost:8081/advjavaproject/userLogin.jsp`.
2. Submit user login by email.
3. Confirm OTP page loads.
4. Complete OTP verification.
5. Confirm user dashboard opens.

## 3. User Workflow

1. From dashboard, open Register Complaint.
2. Submit complaint with category, description, address.
3. Optional: add image up to 1.5 MB.
4. Confirm success flow returns to dashboard and row appears in Recent Complaints.

## 4. Tracking Workflow

1. Open Track Complaint.
2. Search using complaint ID/code + email.
3. Confirm result page loads with status.

## 5. Admin/Officer Workflow

1. Login as admin/officer from admin login page.
2. Confirm dashboard loads.
3. Confirm logout works and returns to login/home.

## 6. Quick Regression Checks

1. No `HTTP 404` on `/actions/...` URLs.
2. No `HTTP 500` with `Unable to compile class for JSP`.
3. No `AbstractMethodError` related to `sendRedirect`.

## 7. Runtime Library Check

In deployed app root, verify `WEB-INF/lib` includes:

- `mysql-connector-java-8.0.26.jar`
- `jakarta.mail-2.0.1.jar`
- `jakarta.activation-api-2.1.3.jar`
- `jakarta.servlet.jsp.jstl-api-3.0.0.jar`
- `jakarta.servlet.jsp.jstl-impl-3.0.1.jar`

If any file is missing, JSP compilation and login/notification flows can fail.
