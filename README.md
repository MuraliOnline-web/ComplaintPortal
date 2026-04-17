# Complaint Portal

This project is a Java web application for complaint registration, tracking, and complaint handling by admins and field officers. It uses JSP pages for the UI, JSP action handlers for server-side logic, MySQL for persistence, and SMTP for OTP and notification emails.

## Project Overview

- Citizens can register, log in with email OTP, file complaints, and track complaint status.
- Field officers can review pending complaints, submit visit reports, and view analytics.
- Admins can search complaints, update complaint status, archive solved records, and run configuration health checks.

## Folder Structure

```text
.
├── config.properties.template
├── SECURITY_SETUP.md
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

## Application Workflow

1. `index.jsp` is the public landing page and route hub.
2. New users register through `userRegister.jsp` and `actions/UserRegisterAction.jsp`.
3. User login uses email plus password in `userLogin.jsp`, then `actions/UserLoginAction.jsp` sends an OTP.
4. OTP verification happens in `verifyOtp.jsp` and `actions/VerifyOtpAction.jsp`.
5. After verification, users reach `userDashboard.jsp` where they can create and track complaints.
6. Complaint submission goes through `registerComplaint.jsp` and `actions/RegisterComplaintAction.jsp`.
7. Complaint tracking goes through `trackComplaint.jsp` and `actions/TrackComplaintAction.jsp`.
8. Admins and officers authenticate through `login.jsp` and `actions/LoginAction.jsp`.
9. Admins use `adminDashboard.jsp`, `analytics.jsp`, and `adminConfigHealth.jsp` to manage and inspect the system.
10. Officers use `officerDashboard.jsp` to review pending complaints and submit reports.

## Included Operations

### Public and User Operations

- User registration
- User login with email OTP
- Forgot password flow with reset OTP
- Password reset
- Complaint registration
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
- Check database and SMTP configuration health

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
| `adminConfigHealth.jsp` | Database and SMTP configuration checks |
| `actions/LogoutAction.jsp` | Logout and session cleanup |

## Core Backend Components

- `src/util/ConfigLoader.java` loads configuration from environment variables first and falls back to `config.properties`.
- `WebContent/WEB-INF/web.xml` sets `index.jsp` as the welcome page and configures the session timeout.
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
- `WEB-INF/lib/` should contain required libraries such as the MySQL connector and mail dependencies.
- Uploaded complaint and report photos are written under `WebContent/assets/images/uploads/` at runtime.

## Security Notes

- Do not commit real database or SMTP credentials.
- `SECURITY_SETUP.md` documents the cleanup steps for exposed secrets.
- Admin and officer accounts should be created manually with strong passwords.

## Entry Pages

- Public home: `WebContent/index.jsp`
- User login: `WebContent/userLogin.jsp`
- User registration: `WebContent/userRegister.jsp`
- Admin/officer login: `WebContent/login.jsp`
- User dashboard: `WebContent/userDashboard.jsp`
- Admin dashboard: `WebContent/adminDashboard.jsp`
- Officer dashboard: `WebContent/officerDashboard.jsp`

## Typical Use Cases

- A citizen registers, verifies OTP, submits a complaint, and later tracks its status.
- A field officer reviews pending complaints and uploads a field report.
- An admin updates a complaint to solved, attaches a solved photo, and archives solved items after reporting.

## Database Setup

Use `db/schema.sql` to create the database and tables, then add privileged users manually for each environment.

## Local Run Steps

1. Install a Java 21+ JDK and a Jakarta-compatible servlet container such as Tomcat 10.x.
2. Create the database and tables by running `db/schema.sql` in MySQL.
3. Copy `config.properties.template` to a local `config.properties` file and set the database and SMTP values.
4. Place the MySQL JDBC driver and Jakarta Mail libraries in `WebContent/WEB-INF/lib/` if they are not already bundled.
5. Deploy the project to Tomcat as a web application.
6. Start the server and open `index.jsp` from the deployed app.

### Suggested SQL Import Order

1. Run `db/schema.sql` first to create the schema and core tables.
2. Add or update admin and officer accounts manually for your environment.
3. Use the migration SQL files only if you are applying a specific database migration path.

### Local Configuration Checklist

- `db.url` points to the active MySQL instance.
- `db.user` and `db.password` match the database account.
- `smtp.host`, `smtp.port`, `smtp.user`, and `smtp.password` are set for OTP and notification mail.
- Uploaded files can be written to `WebContent/assets/images/uploads/` by the server process.

## Notes

- The repository contains both live and archive SQL files to support complaint retention workflows.
- `index.html` is present for static entry support, but `index.jsp` is the primary welcome page.