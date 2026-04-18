<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String successMessage = (String) session.getAttribute("flashMessage");
    String errorMessage = (String) session.getAttribute("flashError");
    if (successMessage != null) session.removeAttribute("flashMessage");
    if (errorMessage != null) session.removeAttribute("flashError");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Complaint Portal - Home</title>
    <meta name="description" content="File complaints, track progress, and stay connected with your city services.">
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" crossorigin="anonymous">
    <style>
        body.homepage {
            background:
                radial-gradient(circle at top left, rgba(79, 70, 229, 0.18), transparent 32%),
                radial-gradient(circle at top right, rgba(14, 165, 233, 0.12), transparent 28%),
                linear-gradient(180deg, #f8fafc 0%, #eef2ff 100%);
            color: #0f172a;
        }

        .home-shell {
            min-height: 100vh;
        }

        .home-navbar {
            backdrop-filter: blur(14px);
            background: rgba(255, 255, 255, 0.72);
            border-bottom: 1px solid rgba(148, 163, 184, 0.2);
        }

        .home-navbar .container,
        main.container {
            max-width: 1260px;
        }

        .home-navbar .navbar-brand span {
            font-size: 1.2rem;
            letter-spacing: -0.02em;
        }

        .home-navbar .navbar-nav .nav-link {
            color: #334155;
            font-weight: 600;
            padding: 0.45rem 0.8rem;
            border-radius: 10px;
            font-size: 0.98rem;
            transition: background-color 0.2s ease, color 0.2s ease;
        }

        .home-navbar .navbar-nav .nav-link:hover,
        .home-navbar .navbar-nav .nav-link:focus {
            background: rgba(79, 70, 229, 0.1);
            color: #312e81;
        }

        .brand-mark {
            width: 46px;
            height: 46px;
            border-radius: 14px;
            object-fit: cover;
            box-shadow: 0 12px 24px rgba(79, 70, 229, 0.18);
        }

        .hero-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 28px;
            background: rgba(255, 255, 255, 0.8);
            box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
            overflow: hidden;
        }

        .hero-copy {
            padding: clamp(2rem, 4vw, 4rem);
        }

        .eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.45rem 0.8rem;
            border-radius: 999px;
            background: rgba(79, 70, 229, 0.08);
            color: #4338ca;
            font-weight: 600;
            font-size: 0.85rem;
        }

        .hero-title {
            font-size: clamp(2.6rem, 6vw, 5.2rem);
            line-height: 0.95;
            letter-spacing: -0.05em;
            font-weight: 800;
            margin-top: 1rem;
        }

        .hero-title span {
            background: linear-gradient(90deg, #4f46e5, #0ea5e9);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        .feature-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            border-radius: 999px;
            padding: 0.6rem 0.9rem;
            background: #ffffff;
            border: 1px solid rgba(148, 163, 184, 0.25);
            box-shadow: 0 12px 30px rgba(15, 23, 42, 0.05);
            margin: 0.35rem 0.35rem 0 0;
            font-size: 0.92rem;
        }

        .showcase-panel {
            width: min(100%, 620px);
            min-height: 340px;
            background:
                linear-gradient(180deg, rgba(15, 23, 42, 0.35), rgba(15, 23, 42, 0.65)),
                url('assets/images/road.jpg') center/cover;
            padding: 2rem;
            color: #fff;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            border-radius: 22px;
            box-shadow: 0 20px 56px rgba(15, 23, 42, 0.2);
        }

        .showcase-wrap {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: clamp(1rem, 1.8vw, 1.5rem);
            height: 100%;
        }

        .showcase-stat {
            background: rgba(255, 255, 255, 0.12);
            border: 1px solid rgba(255, 255, 255, 0.16);
            border-radius: 18px;
            padding: 1rem;
            backdrop-filter: blur(14px);
        }

        .section-title {
            font-weight: 800;
            letter-spacing: -0.03em;
            color: #0f172a;
        }

        .feature-card {
            border: 1px solid rgba(148, 163, 184, 0.2);
            border-radius: 22px;
            background: rgba(255, 255, 255, 0.8);
            box-shadow: 0 16px 40px rgba(15, 23, 42, 0.06);
            height: 100%;
        }

        .feature-icon {
            width: 46px;
            height: 46px;
            border-radius: 14px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #4f46e5, #0ea5e9);
            color: #fff;
            font-weight: 700;
        }

        @media (max-width: 991px) {
            .showcase-panel {
                width: 100%;
                min-height: 320px;
            }
        }

        @media (min-width: 1200px) {
            .home-navbar {
                padding-top: 0.9rem;
                padding-bottom: 0.9rem;
            }

            .home-navbar .navbar-brand {
                gap: 0.9rem;
            }

            .home-navbar .navbar-nav {
                gap: 0.6rem;
            }

            .home-navbar .navbar-nav .nav-link {
                font-size: 1rem;
                padding: 0.55rem 1rem;
            }

            .home-navbar .btn {
                font-size: 0.98rem;
                padding: 0.5rem 1rem;
            }

            .hero-card {
                border-radius: 30px;
            }

            .hero-copy {
                padding: 3.2rem;
            }

            .hero-title {
                font-size: clamp(3.3rem, 4vw, 4.9rem);
                margin-bottom: 1.25rem;
            }

            .hero-card .row {
                align-items: stretch;
            }

            .hero-card .col-lg-6 {
                display: flex;
            }

            .showcase-wrap {
                width: 100%;
                padding: 2.2rem 2rem;
            }

            .showcase-panel {
                width: 100%;
                max-width: 620px;
                min-height: 430px;
            }

            .feature-card {
                padding: 2rem !important;
            }
        }
    </style>
</head>
<body class="homepage">
    <%@ include file="includes/ui-enhancements.jspf" %>
    <!-- Hidden message containers for toast notifications -->
    <% if (successMessage != null) { %>
        <div id="successMessage" style="display:none;"><%= successMessage %></div>
    <% } %>
    <% if (errorMessage != null) { %>
        <div id="errorMessage" style="display:none;"><%= errorMessage %></div>
    <% } %>
    
    <div class="home-shell">
        <nav class="navbar navbar-expand-lg home-navbar sticky-top py-3">
            <div class="container">
                <a class="navbar-brand d-flex align-items-center gap-3 fw-bold text-dark" href="index.jsp">
                    <img src="assets/images/logo.svg" alt="Complaint Portal" class="brand-mark">
                    <span>Complaint Portal</span>
                </a>
                <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#topNav" aria-controls="topNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <div class="collapse navbar-collapse" id="topNav">
                    <ul class="navbar-nav mx-auto mt-3 mt-lg-0 gap-lg-2">
                        <li class="nav-item"><a class="nav-link" href="index.jsp#home">Home</a></li>
                        <li class="nav-item"><a class="nav-link" href="index.jsp#about">About</a></li>
                        <li class="nav-item"><a class="nav-link" href="index.jsp#services">Services</a></li>
                        <li class="nav-item"><a class="nav-link" href="index.jsp#description">Description</a></li>
                    </ul>
                    <div class="d-flex gap-2 mt-3 mt-lg-0">
                        <a class="btn btn-outline-dark" href="userLogin.jsp">Sign In</a>
                        <a class="btn btn-primary" href="userRegister.jsp">Get Started</a>
                    </div>
                </div>
            </div>
        </nav>

        <main id="home" class="container py-4 py-lg-5">
            <nav aria-label="breadcrumb" class="mb-4">
                <ol class="breadcrumb small">
                    <li class="breadcrumb-item active" aria-current="page">Home</li>
                </ol>
            </nav>
            <section id="about" class="hero-card mb-5">
                <div class="row g-0 align-items-center">
                    <div class="col-lg-6">
                        <div class="hero-copy">
                            <div class="eyebrow">
                                <span class="rounded-circle bg-success" style="width:10px;height:10px;display:inline-block;"></span>
                                Civic services made visible
                            </div>
                            <h1 class="hero-title mb-3">
                                Your complaint.<br>
                                <span>Your city responds.</span>
                            </h1>
                            <p class="lead text-secondary mb-4" style="max-width: 46rem;">
                                File issues, track updates, and keep your local services accountable from one clean portal.
                                Designed for citizens, officers, and administrators.
                            </p>

                            <div class="d-flex flex-wrap mt-4">
                                <div class="feature-pill">Fast complaint filing</div>
                                <div class="feature-pill">Live progress tracking</div>
                                <div class="feature-pill">Officer workflows</div>
                                <div class="feature-pill">Admin review & resolution</div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="showcase-wrap">
                            <div class="showcase-panel">
                                <div>
                                    <div class="small text-uppercase fw-semibold opacity-75 mb-2">Community dashboard</div>
                                    <h2 class="display-6 fw-bold mb-3">Clear, trustworthy, public-facing service updates.</h2>
                                    <p class="mb-0 opacity-75">
                                        See who is responsible, what is happening, and when it is resolved.
                                    </p>
                                </div>
                                <div class="row g-3 mt-4">
                                    <div class="col-6">
                                        <div class="showcase-stat">
                                            <div class="small opacity-75">Filed Today</div>
                                            <div class="fs-3 fw-bold">128</div>
                                        </div>
                                    </div>
                                    <div class="col-6">
                                        <div class="showcase-stat">
                                            <div class="small opacity-75">Resolved</div>
                                            <div class="fs-3 fw-bold">84%</div>
                                        </div>
                                    </div>
                                    <div class="col-12">
                                        <div class="showcase-stat">
                                            <div class="small opacity-75">Primary actions</div>
                                            <div class="fw-semibold">Sign in to continue, or register a new user account.</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section id="services" class="mb-5">
                <div class="row g-4">
                    <div class="col-md-4">
                        <div class="feature-card p-4">
                            <div class="feature-icon mb-3">1</div>
                            <h3 class="h5 fw-bold">Submit issues quickly</h3>
                            <p class="text-secondary mb-0">A focused complaint form for citizens with clear categories and evidence upload.</p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="feature-card p-4">
                            <div class="feature-icon mb-3">2</div>
                            <h3 class="h5 fw-bold">Track resolution</h3>
                            <p class="text-secondary mb-0">Users and staff can see complaint status, notes, and updates in one place.</p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="feature-card p-4">
                            <div class="feature-icon mb-3">3</div>
                            <h3 class="h5 fw-bold">Work by role</h3>
                            <p class="text-secondary mb-0">Separate dashboards for citizens, officers, and administrators keep the workflow clean.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section id="description" class="mb-5">
                <div class="feature-card p-4 p-md-5">
                    <h2 class="section-title h3 mb-3">Project Description</h2>
                    <p class="text-secondary mb-0">
                        Complaint Portal is a civic support platform where citizens can register and track complaints,
                        officers can manage field workflows, and administrators can monitor service resolution through
                        dedicated dashboards and analytics.
                    </p>
                </div>
            </section>
        </main>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="assets/js/main.js"></script>
</body>
</html>
