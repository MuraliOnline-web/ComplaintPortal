# Complaint Portal

This project is a Java web application for complaint registration, tracking, and complaint handling by admins and field officers. It uses JSP pages for the UI, JSP action handlers for server-side logic, MySQL for persistence, and SMTP for OTP and notification emails. Complaint registration acknowledgements include both complaint ID and complaint code.

The application uses a clean, direct JSP architecture. `WebContent/` contains the web application source and defines the canonical deployed web application root under Tomcat. Browser requests navigate directly to application JSP pages and action handlers without mediator or forwarder layers.

Current workflow highlights:

- **Direct navigation**: Browser → Actual JSP page → Action handler / logic.
- **Single deployment root**: The contents of `WebContent/` form the deployed web application under Tomcat.
- **No mediator/forwarder layer**: Redundant root-level shims have been completely eliminated.
- **Admin dashboard**: Exposes a direct Config Health shortcut to the admin configuration page.
- **Smoke-test checklist**: Focuses on startup, login, complaint submission, tracking, logout, and runtime library verification.

## Project Overview

- **Citizens**: Register, log in with email OTP, file complaints with optional photo uploads, and track complaint status.
- **Field Officers**: Review pending complaints, submit field visit inspection reports with photos, and view analytics.
- **Admins**: Search complaints, update complaint status, upload resolution photos, archive solved records, run report analytics, and check configuration health.

## Folder Structure

```text
advjavaproject/
├── WebContent/                    # Canonical Tomcat web application root
│   ├── index.jsp
│   ├── index.html
│   ├── login.jsp
│   ├── userLogin.jsp
│   ├── userRegister.jsp
│   ├── verifyOtp.jsp
│   ├── forgotPassword.jsp
│   ├── resetPassword.jsp
│   ├── registerComplaint.jsp
│   ├── complaintSuccess.jsp
│   ├── trackComplaint.jsp
│   ├── trackResult.jsp
│   ├── userDashboard.jsp
│   ├── adminDashboard.jsp
│   ├── officerDashboard.jsp
│   ├── analytics.jsp
│   ├── adminConfigHealth.jsp
│   │
│   ├── actions/
│   │   ├── JSP action handlers
│   │   └── api/
│   │       └── REST/JSON endpoints
│   │
│   ├── assets/
│   │   ├── css/
│   │   ├── js/
│   │   └── images/
│   │       └── uploads/
│   │
│   ├── includes/
│   │
│   └── WEB-INF/
│       ├── web.xml
│       ├── classes/
│       ├── lib/
│       └── tld/
│
├── src/
│   └── util/
│       └── ConfigLoader.java
│
├── db/
├── config.properties.template
├── README.md
└── .gitignore
```

The application uses direct navigation to `WebContent/` as the effective deployment root. All pages and actions are accessed directly at the application context root (e.g., `/index.jsp`, `/actions/...`) without mediator layers.

## Root Documentation

The repository keeps its markdown docs at the top level so they are easy to find from the workspace root:

- [README.md](README.md) - main project guide
- [SECURITY_SETUP.md](SECURITY_SETUP.md) - credential cleanup and secure configuration notes
- [SMOKE_TEST_CHECKLIST.md](SMOKE_TEST_CHECKLIST.md) - redeploy smoke test steps
- [STABLE_BUILD_SUMMARY.md](STABLE_BUILD_SUMMARY.md) - stable build and runtime summary
- [INTEGRATION_VERIFICATION_REPORT.md](INTEGRATION_VERIFICATION_REPORT.md) - backend and JSP verification report

## Application Workflow

1. Open the app at the context URL (e.g. `http://localhost:8081/advjavaproject/`), which lands directly on `/index.jsp`.
2. The landing page exposes the primary citizen, admin, and officer entry points.
3. New citizens register through `/userRegister.jsp` and submit to `/actions/UserRegisterAction.jsp`.
4. Citizen login uses `/userLogin.jsp`, then `/actions/UserLoginAction.jsp` generates and sends an email OTP.
5. OTP verification happens in `/verifyOtp.jsp` and `/actions/VerifyOtpAction.jsp`, routing the user to `/userDashboard.jsp` upon success.
6. Citizens create complaints in `/registerComplaint.jsp`, which submits multipart data to `/actions/RegisterComplaintAction.jsp` and redirects to `/complaintSuccess.jsp`.
7. Complaint tracking is initiated from `/trackComplaint.jsp` and `/actions/TrackComplaintAction.jsp`, forwarding to `/trackResult.jsp`.
8. Admins and officers authenticate through `/login.jsp` and `/actions/LoginAction.jsp`.
9. Admins manage complaints via `/adminDashboard.jsp`, update statuses via `/actions/UpdateStatus.jsp`, search complaints with `/actions/SearchComplaints.jsp`, run analytics in `/analytics.jsp`, and verify setup in `/adminConfigHealth.jsp`.
10. Officers review assigned complaints and submit inspection reports via `/officerDashboard.jsp` and `/actions/FieldOfficerUpdate.jsp`.
11. Logout is handled cleanly by `/actions/LogoutAction.jsp`, which invalidates the session and redirects to `/index.jsp`.

## Current Workflow And Architecture

The project architecture features:

- **Direct JSP navigation**: Clean URLs without intermediate forwarders or shims.
- **Single deployment descriptor**: Located at `WebContent/WEB-INF/web.xml`, defining welcome files (`index.jsp`, `index.html`) and session timeout.
- **Tag Library Definitions**: Jakarta JSTL tag library definitions (`c.tld`, `fn.tld`) are integrated in `WebContent/WEB-INF/tld/`.
- **Runtime libraries**: All JAR dependencies reside in `WebContent/WEB-INF/lib/`.
- **Compiled classes**: Servlets and utility classes reside in `WebContent/WEB-INF/classes/`.

## Included Operations

### Public and User Operations

- Citizen registration
- Citizen login with email OTP
- Forgot password flow with reset OTP
- Password reset
- Complaint registration with optional image upload
- Complaint registration acknowledgement email with complaint ID and code
- Complaint tracking by complaint code or complaint ID
- Logout

### Admin Operations

- View all registered complaints
- Search complaints by code or ID
- Update complaint status (Pending, In Progress, Solved, Rejected)
- Upload resolution/solved photos
- Filter and review analytics by day, month, or year
- Archive solved complaints for a selected period
- Send reminder notifications for pending complaints
- Check database and SMTP configuration health from `/adminConfigHealth.jsp`

### Field Officer Operations

- View pending complaints
- Search complaints by code or ID
- Submit field visit reports with findings and optional inspection photos
- View performance analytics

## JSP To Operation Map

| JSP / Action | Operation |
| --- | --- |
| `/index.jsp` | Public home page and role-based navigation |
| `/userRegister.jsp` + `/actions/UserRegisterAction.jsp` | Create user account |
| `/userLogin.jsp` + `/actions/UserLoginAction.jsp` | User login with OTP delivery |
| `/verifyOtp.jsp` + `/actions/VerifyOtpAction.jsp` | Verify OTP and start user session |
| `/forgotPassword.jsp` + `/actions/ForgotPasswordAction.jsp` | Send password reset OTP |
| `/resetPassword.jsp` + `/actions/ResetPasswordAction.jsp` | Reset password after OTP verification |
| `/login.jsp` + `/actions/LoginAction.jsp` | Admin/officer login |
| `/registerComplaint.jsp` + `/actions/RegisterComplaintAction.jsp` | Submit a new complaint |
| `/trackComplaint.jsp` + `/actions/TrackComplaintAction.jsp` | Track complaint status as a user |
| `/trackResult.jsp` | Display complaint tracking result |
| `/userDashboard.jsp` | User complaint summary and quick actions |
| `/adminDashboard.jsp` + `/actions/GetComplaintByCode.jsp` | Admin complaint search and management |
| `/officerDashboard.jsp` + `/actions/FieldOfficerUpdate.jsp` | Officer complaint review and report submission |
| `/analytics.jsp` + `/actions/SendPendingReminders.jsp` + `/actions/ArchiveSolved.jsp` | Complaint analytics, reminders, and archiving |
| `/adminConfigHealth.jsp` | Database and SMTP configuration checks and health verification |
| `/actions/LogoutAction.jsp` | Logout and session cleanup |

## Core Backend Components

- `src/util/ConfigLoader.java` loads configuration in this prioritized order:
  1. Environment variables (`DB_URL`, `DB_USER`, `DB_PASSWORD`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`)
  2. Java system properties (`-Ddb.url`, `-Dsmtp.host`, etc.)
  3. `config.properties` on classpath (`WebContent/WEB-INF/classes/config.properties`)
  4. Sensible application defaults
- `WebContent/WEB-INF/web.xml` defines web application configuration, welcome files, and session timeout.
- `db/schema.sql` defines the MySQL schema and relational tables.

## Database Tables

- `users`: Stores citizens, officers, and admins.
- `complaints`: Stores complaint details, tracking codes, priority, and status.
- `notifications`: Stores complaint notification history.
- `otp_codes`: Stores OTP hashes and expiry timestamps.
- `officer_reports`: Stores field officer visit reports and inspection findings.

## Configuration

The application expects database and SMTP settings through environment variables, system properties, or a local `config.properties` file.

### Expected Configuration Keys

- `db.url`: JDBC connection URL (e.g. `jdbc:mysql://localhost:3306/complaint_portal?useSSL=false&allowPublicKeyRetrieval=true`)
- `db.user`: MySQL database user
- `db.password`: MySQL database password
- `smtp.host`: SMTP server host
- `smtp.port`: SMTP server port (e.g. 587 or 465)
- `smtp.user`: SMTP username / email address
- `smtp.password`: SMTP app password / secret

`config.properties.template` is provided in the repository root and can be copied to `WebContent/WEB-INF/classes/config.properties` for local development.

### Security Warnings

- **Never commit real database passwords.**
- **Never commit SMTP passwords or app secrets.**
- **Never commit API keys or production credentials.**
- Use environment variables in production or maintain `config.properties` locally (which is ignored by Git).
- See [SECURITY_SETUP.md](SECURITY_SETUP.md) for credential cleanup and security guidelines.

## Dependencies & Runtime

### Target Runtime Environment

- **Java**: Java 17 (Java 11+ compatible)
- **Servlet Container**: Apache Tomcat 10.1.x / 11.x
- **Namespace**: Jakarta EE (`jakarta.servlet.*`, `jakarta.mail.*`)

### Deployed Runtime JARs (`WebContent/WEB-INF/lib/`)

The following verified JARs are bundled directly in `WebContent/WEB-INF/lib/`:

| Library | File | Version | Purpose |
|---|---|---|---|
| **MySQL Connector/J** | `mysql-connector-java-8.0.26.jar` | 8.0.26 | MySQL JDBC driver |
| **Jakarta Mail** | `jakarta.mail-2.0.1.jar` | 2.0.1 | Email & OTP delivery |
| **Jakarta Activation API** | `jakarta.activation-api-2.1.3.jar` | 2.1.3 | MIME type / mail support |
| **Jakarta Servlet JSP API** | `jakarta.servlet.jsp-api-3.0.0.jar` | 3.0.0 | JSP specification API |
| **JSTL API** | `jakarta.servlet.jsp.jstl-api-3.0.0.jar` | 3.0.0 | Standard Tag Library API |
| **JSTL Implementation** | `jakarta.servlet.jsp.jstl-impl-3.0.1.jar` | 3.0.1 | Standard Tag Library Impl |

## File Uploads & Security

- **Upload Directory**: `WebContent/assets/images/uploads/`
- **Permissions**: The Tomcat service process must have write permission to `WebContent/assets/images/uploads/` when complaint attachments, officer reports, or resolution photos are uploaded.
- **Sanitization**: Uploaded filenames are sanitized and stored using unique IDs to prevent path traversal.

## Entry Pages

- Public home: `/index.jsp`
- User login: `/userLogin.jsp`
- User registration: `/userRegister.jsp`
- Admin/officer login: `/login.jsp`
- User dashboard: `/userDashboard.jsp`
- Admin dashboard: `/adminDashboard.jsp`
- Officer dashboard: `/officerDashboard.jsp`
- Admin config health: `/adminConfigHealth.jsp`

## Deployment & Local Run Steps

### 1. Tomcat Context Configuration

The canonical web application root is `c:\advjavaproject\WebContent`. Do **not** deploy the repository root `c:\advjavaproject` as the webapp docBase.

Configure your Tomcat context (in `conf/server.xml` or `conf/Catalina/localhost/advjavaproject.xml`):

```xml
<Context path="/advjavaproject"
         docBase="c:\advjavaproject\WebContent"
         reloadable="true" />
```

- **Tomcat context**: `/advjavaproject`
- **DocBase**: `c:\advjavaproject\WebContent`
- **Expected URL**: `http://localhost:8081/advjavaproject/` (or `http://localhost:8081/advjavaproject/index.jsp`)

### 2. Database Setup

1. Run `db/schema.sql` to create the schema and relational tables.
2. Add initial admin or officer accounts with hashed credentials if needed for your environment.
3. Apply migration scripts under `db/` only if upgrading from an earlier schema version.

### 3. Configuration Setup

Copy `config.properties.template` to `WebContent/WEB-INF/classes/config.properties` (or set environment variables `DB_URL`, `DB_USER`, `DB_PASSWORD`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`).

### 4. Build Java Classes

Compile `src/util/ConfigLoader.java` into `WebContent/WEB-INF/classes/`:

```powershell
javac -d WebContent/WEB-INF/classes src/util/ConfigLoader.java
```

### 5. Start Server and Smoke Test

1. Start Apache Tomcat.
2. Open `http://localhost:8081/advjavaproject/` in your browser.
3. Validate user registration, OTP email delivery, complaint submission, and admin dashboard according to [SMOKE_TEST_CHECKLIST.md](SMOKE_TEST_CHECKLIST.md).

### Redeploy Note

After JSP or class-level configuration changes, clear `tomcat/work/Catalina/localhost/advjavaproject/` before server restart so stale compiled JSP class artifacts are not reused.

## Notes

- The repository contains both live and archive SQL files to support complaint retention workflows.
- `index.jsp` is the primary welcome page configured in `web.xml`.
- All requests navigate directly to the actual JSP pages under the web application root without any intermediary mediator or forwarder layer.