# Complaint Portal

This project is a Java web application for complaint registration, tracking, and complaint handling by admins and field officers. It uses JSP pages for the UI, JSP action handlers for server-side logic, MySQL for persistence, and SMTP for OTP and notification emails. Complaint registration acknowledgements include both complaint ID and complaint code.

The current runtime workflow is root-deployed under Tomcat, with compatibility shims at the project root forwarding to the editable JSP sources in WebContent. That means users open root URLs such as /index.jsp, while the maintained application pages remain under WebContent/. The root deployment is intentional and required for the current workflow.

Current workflow highlights:

- Root URLs are the supported entry points for browser navigation.
- Root JSP/action shims forward into the maintained pages under WebContent/.
- Admin dashboard now exposes a direct Config Health shortcut to the admin configuration page.
- The smoke-test checklist focuses on startup, login, complaint submission, tracking, logout, and runtime library verification.

## Project Overview

- Citizens can register, log in with email OTP, file complaints, and track complaint status.
- Field officers can review pending complaints, submit visit reports, and view analytics.
- Admins can search complaints, update complaint status, archive solved records, and run configuration health checks.

## Folder Structure

```text
.
├── config.properties.template
├── INTEGRATION_VERIFICATION_REPORT.md
├── README.md
├── SECURITY_SETUP.md
├── SMOKE_TEST_CHECKLIST.md
├── STABLE_BUILD_SUMMARY.md
├── actions/
│   ├── ArchiveSolved.jsp
│   ├── FieldOfficerUpdate.jsp
│   ├── ForgotPasswordAction.jsp
│   ├── GenerateReports.jsp
│   ├── GetComplaintByCode.jsp
│   ├── LoginAction.jsp
│   ├── LogoutAction.jsp
│   ├── RegisterComplaintAction.jsp
│   ├── ResetPasswordAction.jsp
│   ├── SearchComplaints.jsp
│   ├── SendPendingReminders.jsp
│   ├── TrackComplaintAction.jsp
│   ├── UpdateStatus.jsp
│   ├── UpdateStatusSafe.jsp
│   ├── UserLoginAction.jsp
│   ├── UserRegisterAction.jsp
│   └── VerifyOtpAction.jsp
├── index.jsp
├── login.jsp
├── userLogin.jsp
├── userRegister.jsp
├── verifyOtp.jsp
├── registerComplaint.jsp
├── complaintSuccess.jsp
├── trackComplaint.jsp
├── trackResult.jsp
├── userDashboard.jsp
├── adminDashboard.jsp
├── officerDashboard.jsp
├── analytics.jsp
├── forgotPassword.jsp
├── resetPassword.jsp
├── db/
│   ├── archive.sql
│   ├── migration_auth_zero_cost.sql
│   ├── migration_option_b.sql
│   ├── schema.sql
│   └── schema2.sql
├── src/
│   └── util/
│       └── ConfigLoader.java
└── WebContent/
    ├── index.html
    ├── index.jsp
    ├── login.jsp
    ├── userLogin.jsp
    ├── userRegister.jsp
    ├── forgotPassword.jsp
    ├── resetPassword.jsp
    ├── verifyOtp.jsp
    ├── registerComplaint.jsp
    ├── complaintSuccess.jsp
    ├── trackComplaint.jsp
    ├── trackResult.jsp
    ├── adminDashboard.jsp
    ├── officerDashboard.jsp
    ├── userDashboard.jsp
    ├── analytics.jsp
    ├── adminConfigHealth.jsp
    ├── actions/
    │   ├── ArchiveSolved.jsp
    │   ├── FieldOfficerUpdate.jsp
    │   ├── ForgotPasswordAction.jsp
    │   ├── GenerateReports.jsp
    │   ├── GetComplaintByCode.jsp
    │   ├── LoginAction.jsp
    │   ├── LogoutAction.jsp
    │   ├── RegisterComplaintAction.jsp
    │   ├── ResendResetOtpAction.jsp
    │   ├── ResetPasswordAction.jsp
    │   ├── SearchComplaints.jsp
    │   ├── SendPendingReminders.jsp
    │   ├── TrackComplaintAction.jsp
    │   ├── UpdateStatus.jsp
    │   ├── UpdateStatusSafe.jsp
    │   ├── UserLoginAction.jsp
    │   ├── UserRegisterAction.jsp
    │   └── VerifyOtpAction.jsp
    ├── assets/
    │   ├── css/
    │   │   └── style.css
    │   ├── images/
    │   └── js/
    │       ├── chart.js
    │       └── main.js
    └── WEB-INF/
        ├── web.xml
        ├── classes/
        │   └── util/
        └── lib/
```

The root-level JSP files and actions are compatibility shims for Tomcat root deployment. The editable application sources remain under WebContent/, and the root copies forward requests so the app works after redeploy and refresh. Do not delete the root shims unless the deployment model is changed everywhere at once.

## Root Documentation

The repository keeps its markdown docs at the top level so they are easy to find from the workspace root.

- [README.md](README.md) - main project guide
- [SECURITY_SETUP.md](SECURITY_SETUP.md) - credential cleanup and secure configuration notes
- [SMOKE_TEST_CHECKLIST.md](SMOKE_TEST_CHECKLIST.md) - redeploy smoke test steps
- [STABLE_BUILD_SUMMARY.md](STABLE_BUILD_SUMMARY.md) - stable build and runtime summary
- [INTEGRATION_VERIFICATION_REPORT.md](INTEGRATION_VERIFICATION_REPORT.md) - backend and JSP verification report

## Application Workflow

1. Open the app at the root URL, which lands on the root `index.jsp` shim and then routes into the maintained page under `WebContent/index.jsp`.
2. The landing page exposes the primary user, admin, and officer entry points.
3. New users register through the root `userRegister.jsp` entry page and `actions/UserRegisterAction.jsp`.
4. User login uses the root `userLogin.jsp`, then `actions/UserLoginAction.jsp` sends an OTP to the registered email.
5. OTP verification happens in `verifyOtp.jsp` and `actions/VerifyOtpAction.jsp`, which routes the user to the correct dashboard by role.
6. After verification, users reach `userDashboard.jsp` where they can create complaints, view recent complaints, and move into tracking.
7. Complaint submission goes through `registerComplaint.jsp` and `actions/RegisterComplaintAction.jsp`.
8. Complaint tracking goes through `trackComplaint.jsp` and `actions/TrackComplaintAction.jsp`, which forwards to `trackResult.jsp` when a match is found.
9. Admins and officers authenticate through `login.jsp` and `actions/LoginAction.jsp`.
10. Admins use `adminDashboard.jsp` for complaint review and status updates, `analytics.jsp` for reporting, and `adminConfigHealth.jsp` for database and SMTP health checks.
11. Officers use `officerDashboard.jsp` to review pending complaints and submit reports.
12. Logout is handled by `actions/LogoutAction.jsp`, which clears the session and returns to the home page.

## Current Workflow And Recent Changes

The current project state reflects the following workflow and fixes:

- Root JSP and action shims are the supported navigation layer for Tomcat root deployment.
- `WEB-INF/web.xml` exists at the deployment root and defines welcome-file handling for `index.html` and `index.jsp`.
- Admin dashboard routing now includes a direct link to `adminConfigHealth.jsp` so the config-health page is reachable from the normal admin workflow.
- Safe header-based redirects are used in workflow-critical JSP action handlers to avoid redirect compile/runtime issues.
- Complaint tracking now resolves to `trackResult.jsp` after a successful lookup.
- Logout returns users to the home page after clearing the session.
- The top-level smoke checklist documents the current redeploy verification path for startup, login, complaint creation, tracking, admin/officer access, redirect checks, and runtime libraries.
- The project keeps the maintained UI and action implementations under `WebContent/` while retaining root compatibility shims for runtime entry.

Recent additions and fixes:

- Added or preserved root compatibility routing for the main JSP pages.
- Added or preserved root compatibility routing for `/actions/...` handlers.
- Added the admin Config Health shortcut from the admin dashboard.
- Kept complaint tracking, OTP verification, dashboard navigation, and logout paths aligned with the current root deployment model.
- Kept runtime libraries in `WEB-INF/lib/` for MySQL, Jakarta Mail, activation, and JSTL.

## Included Operations

### Public and User Operations

- User registration
- User login with email OTP
- Forgot password flow with reset OTP
- Password reset
- Complaint registration
- Complaint registration acknowledgement email with complaint ID and complaint code
- Complaint tracking by complaint code or complaint ID
- Logout

### Admin Operations

- View all complaints
- Search complaints by code or ID
- Update complaint status
- Upload solved complaint photos
- Run analytics by day, month, or year
- Archive solved complaints for a selected period
- Send pending reminder notifications
- Check database and SMTP configuration health from the admin dashboard
- Return to analytics or home from the config-health page

### Field Officer Operations

- View pending complaints
- Search complaints by code or ID
- Submit field visit reports
- Add officer notes and optional report photos
- View analytics

## JSP To Operation Map

| JSP / Action | Operation |
| --- | --- |
| `index.jsp` | Public home page and role-based navigation |
| `userRegister.jsp` + `actions/UserRegisterAction.jsp` | Create user account |
| `userLogin.jsp` + `actions/UserLoginAction.jsp` | User login with OTP delivery |
| `verifyOtp.jsp` + `actions/VerifyOtpAction.jsp` | Verify OTP and start user session |
| `forgotPassword.jsp` + `actions/ForgotPasswordAction.jsp` | Send password reset OTP |
| `resetPassword.jsp` + `actions/ResetPasswordAction.jsp` | Reset password after OTP verification |
| `login.jsp` + `actions/LoginAction.jsp` | Admin/officer login |
| `registerComplaint.jsp` + `actions/RegisterComplaintAction.jsp` | Submit a new complaint |
| `trackComplaint.jsp` + `actions/TrackComplaintAction.jsp` | Track complaint status as a user |
| `trackResult.jsp` | Display complaint tracking result |
| `userDashboard.jsp` | User complaint summary and quick actions |
| `adminDashboard.jsp` + `actions/GetComplaintByCode.jsp` | Admin complaint search and management |
| `officerDashboard.jsp` + `actions/FieldOfficerUpdate.jsp` | Officer complaint review and report submission |
| `analytics.jsp` + `actions/SendPendingReminders.jsp` + `actions/ArchiveSolved.jsp` | Complaint analytics, reminders, and archiving |
| `adminConfigHealth.jsp` | Database and SMTP configuration checks and quick health verification |
| `actions/LogoutAction.jsp` | Logout and session cleanup |

## Core Backend Components

- `src/util/ConfigLoader.java` loads configuration in this order: environment variables, Java system properties, local `config.properties`, then default values.
- `WEB-INF/web.xml` sets `index.html` and `index.jsp` as welcome pages and configures the session timeout.
- The root `WEB-INF/web.xml` is part of the deployed runtime layout, while `WebContent/WEB-INF/web.xml` is kept alongside the editable web content layout.
- `db/schema.sql` defines the MySQL schema used by the application.

## Database Tables

- `users` stores citizens, officers, and admins.
- `complaints` stores complaint details and status.
- `notifications` stores complaint notification history.
- `otp_codes` stores OTP hashes and expiry timestamps.
- `officer_reports` stores field officer visit reports.

## Configuration

The application expects database and SMTP settings through environment variables or a local properties file.

Common keys:

- `db.url`
- `db.user`
- `db.password`
- `smtp.host`
- `smtp.port`
- `smtp.user`
- `smtp.password`

`config.properties.template` can be copied to a local `config.properties` file for development.

## Runtime Notes

- The app is JSP-based and intended for deployment on a Jakarta-compatible servlet container such as Tomcat.
- `WEB-INF/lib/` at the deployment root should contain required libraries such as the MySQL connector, mail, and JSTL dependencies.
- Uploaded complaint and report photos are written under `WebContent/assets/images/uploads/` at runtime.
- The root shims exist so the app keeps working when the container serves the deployment root directly.
- `WebContent/` remains the editable source layout, but runtime access should still be validated from the root deployment URLs.

## Security Notes

- Do not commit real database or SMTP credentials.
- [SECURITY_SETUP.md](SECURITY_SETUP.md) documents the cleanup steps for exposed secrets.
- Admin and officer accounts should be created manually with strong passwords.

## Entry Pages

- Public home: `index.jsp`
- User login: `userLogin.jsp`
- User registration: `userRegister.jsp`
- Admin/officer login: `login.jsp`
- User dashboard: `userDashboard.jsp`
- Admin dashboard: `adminDashboard.jsp`
- Officer dashboard: `officerDashboard.jsp`
- Admin config health: `adminConfigHealth.jsp`

## Typical Use Cases

- A citizen registers, verifies OTP, submits a complaint, and later tracks its status.
- A field officer reviews pending complaints and uploads a field report.
- An admin updates a complaint to solved, attaches a solved photo, and archives solved items after reporting.

## Database Setup

Use `db/schema.sql` to create the database and tables, then add privileged users manually for each environment.

## Smoke Testing

Use [SMOKE_TEST_CHECKLIST.md](SMOKE_TEST_CHECKLIST.md) after each redeploy or route-related change.

The checklist currently verifies:

- Root app startup and landing page resolution.
- User login, OTP verification, and user dashboard access.
- Complaint registration and complaint row refresh.
- Complaint tracking and tracking result rendering.
- Admin and officer dashboard access, plus logout.
- Basic route regression checks for `/actions/...` URLs and JSP compilation failures.
- Required runtime libraries in `WEB-INF/lib/`.

If you are validating a route-related change, start with the checklist before trying to debug deeper application behavior.

## Local Run Steps

1. Install a Java 11+ JDK and a Jakarta-compatible servlet container such as Tomcat 10.x.
2. Create the database and tables by running `db/schema.sql` in MySQL.
3. Copy `config.properties.template` to a local `config.properties` file and set the database and SMTP values.
4. Place the MySQL JDBC driver, Jakarta Mail libraries, and JSTL libraries in `WEB-INF/lib/` at the deployed app root if they are not already bundled.
5. Deploy the project so the root shims and `WEB-INF/` are in the webapp root, with WebContent kept as the source layout.
6. Start the server and open `http://localhost:8081/advjavaproject/` (with trailing slash) or `http://localhost:8081/advjavaproject/index.jsp`.
7. Avoid opening `http://localhost:8081/advjavaproject` without the trailing slash on environments where Tomcat context-root redirect behavior is customized, because it may return 500 even when the app itself is healthy.

### Redeploy Note

- After JSP or class-level compatibility/configuration changes, clear `tomcat/work/Catalina/localhost/<app-context>/` before restart so stale compiled JSP artifacts are not reused.
- If a Tomcat context-root redirect returns 500 without the trailing slash, keep using the trailing-slash URL and verify the page-level routes instead of assuming the application is broken.

### Suggested SQL Import Order

1. Run `db/schema.sql` first to create the schema and core tables.
2. Add or update admin and officer accounts manually for your environment.
3. Use the migration SQL files only if you are applying a specific database migration path.

### Local Configuration Checklist

- `db.url` points to the active MySQL instance.
- `db.user` and `db.password` match the database account.
- `smtp.host`, `smtp.port`, `smtp.user`, and `smtp.password` are set for OTP and notification mail.
- Uploaded files can be written to `WebContent/assets/images/uploads/` by the server process.
- The deployed root contains `WEB-INF/` and the root JSP compatibility shims.
- The admin dashboard exposes Config Health so operators can quickly verify database and SMTP settings.

## Notes

- The repository contains both live and archive SQL files to support complaint retention workflows.
- `index.html` is present for static entry support, but `index.jsp` is the primary welcome page.
- The current route model expects both root shims and the maintained `WebContent/` pages to stay in sync.