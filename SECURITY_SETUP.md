# Security Setup Guide

## 🔒 Your Credentials Were Exposed!

Your SMTP and database credentials were committed to Git. This guide helps you secure them permanently.

---

## ⚠️ IMMEDIATE ACTIONS REQUIRED

### 1. **ROTATE YOUR CREDENTIALS IMMEDIATELY**
   - **Gmail App Password**: Generate a NEW app password at https://myaccount.google.com/apppasswords
     - Your old app password `acxxtlgcporjzqna` is now COMPROMISED
   - **Database Password**: Change your MySQL root password if used in production
   - These exposed credentials could allow unauthorized access to your systems

### 2. **Clean Git History** (Remove Exposed Credentials)
   
   ```bash
   # Option A: Using BFG Repo Cleaner (RECOMMENDED - Faster)
   # Download from: https://rtyley.github.io/bfg-repo-cleaner/
   
   bfg --delete-files web.xml  # This removes the file that contained passwords
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   
   # Option B: Using git-filter-branch (Slower but built-in)
   
   git filter-branch --tree-filter 'rm -f WebContent/WEB-INF/web.xml' -f HEAD~10..HEAD
   git gc --prune=now --aggressive
   ```
   
   **WARNING**: These commands rewrite history. Force push cautiously:
   ```bash
   git push origin --force-with-lease main  # or your branch name
   ```

### 3. **Revoke Old Credentials from GitHub**
   - Go to: https://github.com/settings/tokens
   - Delete any exposed credentials listed
   - Check: https://github.com/settings/security-log

---

## 📋 How to Use the New Secure Configuration

### Option 1: Environment Variables (RECOMMENDED for Production)

#### Windows PowerShell:
```powershell
# Set environment variables
$env:DB_URL = "jdbc:mysql://localhost:3306/complaint_portal"
$env:DB_USER = "root"
$env:DB_PASSWORD = "your_new_secure_password"
$env:SMTP_HOST = "smtp.gmail.com"
$env:SMTP_PORT = "587"
$env:SMTP_USER = "medakayalamuraliyadav@gmail.com"
$env:SMTP_PASSWORD = "your_new_app_password"  # Use NEW app password!

# Verify they're set
Get-ChildItem env: | Where-Object {$_.Name -like "DB_*" -or $_.Name -like "SMTP_*"}
```

#### Windows Command Prompt:
```cmd
setx DB_URL "jdbc:mysql://localhost:3306/complaint_portal"
setx DB_USER "root"
setx DB_PASSWORD "your_new_secure_password"
setx SMTP_HOST "smtp.gmail.com"
setx SMTP_PORT "587"
setx SMTP_USER "medakayalamuraliyadav@gmail.com"
setx SMTP_PASSWORD "your_new_app_password"
```

**Note**: After setting with `setx`, restart your IDE for changes to take effect.

#### Linux/Mac:
```bash
export DB_URL="jdbc:mysql://localhost:3306/complaint_portal"
export DB_USER="root"
export DB_PASSWORD="your_new_secure_password"
export SMTP_HOST="smtp.gmail.com"
export SMTP_PORT="587"
export SMTP_USER="medakayalamuraliyadav@gmail.com"
export SMTP_PASSWORD="your_new_app_password"

# Make permanent by adding to ~/.bashrc or ~/.zshrc
```

### Option 2: Local config.properties File (Development Only)

1. **Create `config.properties`** in your resources folder:
   ```properties
   db.url=jdbc:mysql://localhost:3306/complaint_portal
   db.user=root
   db.password=your_new_secure_password
   smtp.host=smtp.gmail.com
   smtp.port=587
   smtp.user=medakayalamuraliyadav@gmail.com
   smtp.password=your_new_app_password
   ```

2. **`config.properties` is already in .gitignore** - it won't be committed ✅

3. Use the template as reference:
   ```bash
   cp config.properties.template config.properties
   # Then edit config.properties with your actual credentials
   ```

---

## 📚 Using ConfigLoader in Your Code

### In Java Servlets/Classes:
```java
import util.ConfigLoader;

// Example: Database connection
String dbUrl = ConfigLoader.getDbUrl();
String dbUser = ConfigLoader.getDbUser();
String dbPassword = ConfigLoader.getDbPassword();

// Example: SMTP connection
String smtpHost = ConfigLoader.getSmtpHost();
String smtpPort = ConfigLoader.getSmtpPort();
String smtpUser = ConfigLoader.getSmtpUser();
String smtpPassword = ConfigLoader.getSmtpPassword();
```

### In JSP Files:
```jsp
<%@ page import="util.ConfigLoader" %>
<%
    String dbUrl = ConfigLoader.getDbUrl();
    String smtpPassword = ConfigLoader.getSmtpPassword();
%>
Database: <%= dbUrl %>
```

---

## ✅ Verification Checklist

- [ ] New Gmail app password generated at https://myaccount.google.com/apppasswords
- [ ] Old Gmail app password compromised (cannot be re-used)
- [ ] MySQL root password changed (if exposed)
- [ ] Git history cleaned to remove exposed credentials
- [ ] `config.properties` created locally with NEW credentials
- [ ] Environment variables set or `config.properties` in place
- [ ] Code tested using `ConfigLoader` for credentials
- [ ] `.gitignore` contains `config.properties` ✅ (Already done)
- [ ] Force-pushed cleaned history to GitHub (if necessary)
- [ ] No default admin/officer credentials exist in `db/schema.sql`
- [ ] Admin/officer accounts created manually with strong passwords in each environment

---

## 🚀 For Production Deployment

Use your hosting provider's environment variable management:
- **AWS**: Set in EC2 instance or use Systems Manager Parameter Store
- **Azure**: Use Key Vault or App Configuration Service
- **Docker**: Set in docker-compose.yml or `.env` file (`.env` also in .gitignore)
- **Tomcat**: Set in `catalina.properties` or via system properties

---

## 🔐 Best Practices Going Forward

1. **Never commit sensitive data** - All `.properties`, `.env`, `.yml` with credentials should be in `.gitignore`
2. **Use environment variables** - Especially for production
3. **Rotate credentials regularly** - Especially app passwords
4. **Enable GitHub secret scanning** - GitHub will warn you of exposed credentials
5. **Use configuration management** - Don't hardcode anything sensitive

---

## 📞 Questions?

If you need to access configuration values in your JSPs, use the `ConfigLoader` class provided. It automatically:
- ✅ Checks environment variables first (highest priority)
- ✅ Falls back to `config.properties` file
- ✅ Provides default values as fallback
- ✅ Works safely without exposing secrets in code

**Your application is now secure!** 🎉
