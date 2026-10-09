# Security Policy

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.** Publicly disclosing a vulnerability before it's fixed gives attackers a head start against anyone running this project.

Instead, report it privately through **GitHub Private Vulnerability Reporting**: go to this repository's **Security** tab → **Report a vulnerability** ([direct link](https://github.com/nncast/flutter-barangay-service-request-app/security/advisories/new)). This opens a private conversation visible only to the maintainer, and lets you track the fix without exposing details publicly. ([GitHub's guide to reporting a vulnerability](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability))

When reporting, please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce it (a minimal example is ideal)
- The affected version/commit, if known
- Any suggested fix, if you have one — optional, but appreciated

## What to Expect

This is a small, single-maintainer project (a student project, not a funded security team), so please have reasonable patience — but every report will get a response acknowledging receipt, and a fix or mitigation plan once the issue is understood. Credit is happily given in the fix's release notes unless you'd prefer to stay anonymous.

## Scope

This covers the Flutter client in this repo — how it signs in and stores the session token (`shared_preferences`), how it calls the API (`lib/core/api_service.dart`), and how it opens links (`url_launcher`).

Problems on the server side — for example a resident reading another resident's requests, or a non-admin reaching `/admin/*` endpoints — belong to the backend. Please report those to [laravel-barangay-service-request-api](https://github.com/nncast/laravel-barangay-service-request-api/security) instead. Hiding admin screens in the app is not a security boundary; the API is.

Out of scope: the demo accounts listed in the README (they are seed data for local testing), and vulnerabilities in Flutter or third-party packages themselves (please report those upstream).

## Supported Versions

As a single-track project without parallel maintained release branches, only the **latest version on `main`** receives security fixes. If you're running an older version, please update before reporting an issue that's already fixed.
