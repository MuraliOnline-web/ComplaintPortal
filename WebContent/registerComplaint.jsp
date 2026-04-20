<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String role = (String) session.getAttribute("role");
    String ctx = request.getContextPath();
    String base = request.getRequestURI().contains("/WebContent/") ? (ctx + "/WebContent") : ctx;
    String homeHref = base + "/index.jsp";
    String dashboardHref = base + "/userDashboard.jsp";
    String logoutHref = base + "/actions/LogoutAction.jsp";
    String styleHref = base + "/assets/css/style.css";
    String scriptHref = base + "/assets/js/main.js";
    String logoHref = base + "/assets/images/logo.svg";
    String roadImageHref = base + "/assets/images/road.jpg";
    try {
        if (application.getResource("/index.jsp") != null) homeHref = ctx + "/index.jsp";
        if (application.getResource("/userDashboard.jsp") != null) dashboardHref = ctx + "/userDashboard.jsp";
        if (application.getResource("/actions/LogoutAction.jsp") != null) logoutHref = ctx + "/actions/LogoutAction.jsp";
        if (application.getResource("/assets/css/style.css") != null) styleHref = ctx + "/assets/css/style.css";
        if (application.getResource("/assets/js/main.js") != null) scriptHref = ctx + "/assets/js/main.js";
        if (application.getResource("/assets/images/logo.svg") != null) logoHref = ctx + "/assets/images/logo.svg";
        if (application.getResource("/assets/images/road.jpg") != null) roadImageHref = ctx + "/assets/images/road.jpg";
    } catch (Exception ignore) {
        // Use computed fallbacks.
    }
    if (role == null || !"user".equals(role)) {
        response.sendRedirect(base + "/userLogin.jsp?required=1");
        return;
    }

    String userName = session.getAttribute("userName") != null ? String.valueOf(session.getAttribute("userName")) : "";
    String userEmail = session.getAttribute("userEmail") != null ? String.valueOf(session.getAttribute("userEmail")) : "";
    String userMobile = session.getAttribute("userMobile") != null ? String.valueOf(session.getAttribute("userMobile")) : "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Register Complaint</title>
    <link rel="stylesheet" href="<%= styleHref %>">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.form-page {
            background:
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.14), transparent 30%),
                radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.1), transparent 32%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
            min-height: 100vh;
        }

        .page-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
            overflow: hidden;
        }

        .hero-side {
            background:
                linear-gradient(180deg, rgba(15, 23, 42, 0.32), rgba(15, 23, 42, 0.68)),
                url('<%= roadImageHref %>') center/cover;
            color: #fff;
            min-height: 100%;
            padding: 2.5rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .field-wrap input,
        .field-wrap select,
        .field-wrap textarea {
            padding-left: 2.5rem;
        }

        .field-icon {
            position: absolute;
            left: 14px;
            top: 16px;
            color: #64748b;
        }

        .upload-box {
            border: 2px dashed #cbd5e1;
            border-radius: 18px;
            padding: 1.25rem;
            background: #f8fafc;
        }

        .file-label {
            border-radius: 14px;
            border: 1px solid rgba(148, 163, 184, 0.25);
            padding: 0.85rem 1rem;
            background: #fff;
            width: 100%;
        }
    </style>
</head>
<body class="form-page">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <!-- Toast container for notifications -->
    <div id="toastContainer"></div>
    
    <nav class="navbar navbar-expand-lg bg-white bg-opacity-75 backdrop-blur-sm sticky-top border-bottom border-light-subtle">
        <div class="container py-2">
            <a class="navbar-brand fw-bold d-flex align-items-center gap-2" href="<%= homeHref %>">
                <img src="<%= logoHref %>" alt="Complaint Portal" style="width:40px;height:40px;border-radius:12px;object-fit:cover;">
                <span>Complaint Portal</span>
            </a>
            <div class="ms-auto d-flex gap-2">
                <a href="<%= dashboardHref %>" class="btn btn-outline-primary">Dashboard</a>
                <a href="<%= logoutHref %>" class="btn btn-outline-danger" data-confirm-logout data-confirm-message="You are about to log out of your account." data-logout-url="<%= logoutHref %>">Logout</a>
            </div>
        </div>
    </nav>

    <main class="container py-4 py-lg-5">
        <nav aria-label="breadcrumb" class="mb-4">
            <ol class="breadcrumb small">
                <li class="breadcrumb-item"><a href="<%= homeHref %>">Home</a></li>
                <li class="breadcrumb-item"><a href="<%= dashboardHref %>">Dashboard</a></li>
                <li class="breadcrumb-item active" aria-current="page">Register Complaint</li>
            </ol>
        </nav>
        <div class="page-card">
            <div class="row g-0">
                <div class="col-lg-4 d-none d-lg-block">
                    <div class="hero-side">
                        <div>
                            <div class="small text-white-50 text-uppercase fw-semibold">New complaint</div>
                            <h1 class="display-6 fw-bold mt-2" style="line-height:1.05;">Describe the issue clearly and add supporting evidence.</h1>
                            <p class="mt-3 mb-0 text-white-75">Your report will be submitted to the backend and stored against your user account for tracking.</p>
                        </div>
                        <div class="row g-3 mt-4">
                            <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Account</div><div class="fw-semibold"><%= userName %></div></div></div>
                            <div class="col-6"><div class="bg-white bg-opacity-10 border border-white border-opacity-10 rounded-4 p-3"><div class="small text-white-50">Status</div><div class="fw-semibold">Pending review</div></div></div>
                        </div>
                    </div>
                </div>
                <div class="col-lg-8">
                    <div class="p-4 p-md-5">
                        <div class="d-flex align-items-start justify-content-between flex-wrap gap-3 mb-4">
                            <div>
                                <h2 class="h3 fw-bold mb-1">Register a Complaint</h2>
                                <p class="text-secondary mb-0">The more detail you provide, the faster the resolution.</p>
                            </div>
                            <div class="d-flex gap-2">
                                <a href="<%= dashboardHref %>" class="btn btn-outline-primary">Back to Dashboard</a>
                                <a href="<%= homeHref %>" class="btn btn-outline-secondary">Home</a>
                            </div>
                        </div>

                        <% if (request.getParameter("success") != null) { %>
                            <div class="alert alert-success"><%= request.getParameter("success") %></div>
                        <% } %>
                        <% if (request.getParameter("error") != null) { %>
                            <div class="alert alert-danger"><%= request.getParameter("error") %></div>
                        <% } %>

                        <form id="complaintForm" action="actions/RegisterComplaintAction.jsp" method="post" class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Name</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">👤</span>
                                    <input type="text" name="name" class="form-control form-control-lg" value="<%= userName %>" readonly>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Email</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">@</span>
                                    <input type="email" name="email" class="form-control form-control-lg" value="<%= userEmail %>" readonly>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Mobile</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">☎</span>
                                    <input type="text" name="mobile" class="form-control form-control-lg" value="<%= userMobile %>" readonly>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-semibold">Category</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">▣</span>
                                    <select name="category" class="form-select form-select-lg" required>
                                        <option value="">Select category</option>
                                        <option value="WaterTap">Water Tap</option>
                                        <option value="Electricity">Electricity</option>
                                        <option value="Road">Road</option>
                                        <option value="Sanitation">Sanitation</option>
                                        <option value="Other">Other</option>
                                    </select>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Description</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">✎</span>
                                    <textarea name="description" class="form-control form-control-lg" rows="5" placeholder="Describe the complaint in detail" required></textarea>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Address</label>
                                <div class="position-relative field-wrap">
                                    <span class="field-icon">⌂</span>
                                    <input type="text" name="address" class="form-control form-control-lg" placeholder="Full location or landmark" required>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-semibold">Photo attachment</label>
                                <div class="upload-box">
                                    <input id="photoInput" type="file" name="photo" class="file-label" accept="image/*">
                                    <input id="photoData" type="hidden" name="photoData">
                                    <input id="photoName" type="hidden" name="photoName">
                                    <div class="text-secondary small mt-2">Optional image upload. For stability, keep image size up to 1.5 MB.</div>
                                </div>
                            </div>
                            <div class="col-12 d-flex flex-wrap gap-2 justify-content-between align-items-center mt-2">
                                <button type="submit" class="btn btn-primary btn-lg">Submit Complaint</button>
                                <a href="<%= dashboardHref %>" class="btn btn-outline-secondary">Cancel</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="<%= scriptHref %>"></script>
    <script>
        (function () {
            var form = document.getElementById('complaintForm');
            var photoInput = document.getElementById('photoInput');
            var photoData = document.getElementById('photoData');
            var photoName = document.getElementById('photoName');
            if (!form || !photoInput || !photoData || !photoName) return;

            form.addEventListener('submit', function (e) {
                if (!photoInput.files || photoInput.files.length === 0) {
                    photoData.value = '';
                    photoName.value = '';
                    return;
                }

                var file = photoInput.files[0];
                if (!file.type || file.type.indexOf('image/') !== 0) {
                    e.preventDefault();
                    alert('Please upload an image file.');
                    return;
                }

                if (file.size > 1572864) {
                    e.preventDefault();
                    alert('Image is too large. Please upload up to 1.5 MB.');
                    return;
                }

                // Convert selected image to base64 so submission remains stable without multipart parsing.
                if (!photoData.value) {
                    e.preventDefault();
                    var reader = new FileReader();
                    reader.onload = function () {
                        photoData.value = String(reader.result || '');
                        photoName.value = String(file.name || 'upload.jpg');
                        form.submit();
                    };
                    reader.onerror = function () {
                        alert('Could not read selected image. Please try another file.');
                    };
                    reader.readAsDataURL(file);
                }
            });
        })();
    </script>
</body>
</html>
