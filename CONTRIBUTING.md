# Contributing

Thank you for your interest in contributing to the **Barangay Service System** mobile app!
Contributions are welcome. Please follow these guidelines to keep things smooth.

The app talks to a separate backend, [laravel-barangay-service-request-api](https://github.com/nncast/laravel-barangay-service-request-api). If your change needs a new or changed API endpoint, open a matching pull request there as well and link the two.

## Development workflow

1. **Fork the repository**
   - Go to [nncast/flutter-barangay-service-request-app](https://github.com/nncast/flutter-barangay-service-request-app).
   - Click the **Fork** button in the top-right corner to create a copy under your GitHub account.
   - Clone your fork locally:
     ```bash
     git clone https://github.com/<your-username>/flutter-barangay-service-request-app.git
     cd flutter-barangay-service-request-app
     ```
   - Add the original repository as an upstream remote so you can sync changes:
     ```bash
     git remote add upstream https://github.com/nncast/flutter-barangay-service-request-app.git
     ```

2. **Create a branch** from `main` in your fork:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**, then commit and push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Open a pull request** against `nncast/flutter-barangay-service-request-app:main`.

## Before you submit

- Keep commit messages clear and descriptive.
- Avoid committing secrets, credentials, build output (`build/`), or IDE files.
- Don't hard-code your own API address (e.g. your LAN IP) in `lib/core/api_service.dart`. Pass it at run time with `--dart-define=API_BASE_URL=...` instead.
- If you add or change behavior, update relevant documentation.
- Run the analyzer and tests before opening a pull request:
  ```bash
  flutter analyze
  flutter test
  ```

## Code style

- Follow the existing project conventions (Provider for state, API calls in `lib/core/api_service.dart`).
- Prefer small, reviewable changes.
- Do not add unrelated formatting changes.

## Pull requests

Pull requests should include:

- a short summary of the change
- any relevant context or motivation
- testing steps or validation performed (and which platform you ran it on)

## Security

Do not commit sensitive values such as API tokens, passwords, keystores, or private configuration.

For security reports, follow [SECURITY.md](https://github.com/nncast/flutter-barangay-service-request-app/blob/main/SECURITY.md).
