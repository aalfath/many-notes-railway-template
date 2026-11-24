# Changelog

Breaking changes are listed first in each entry.

## 0.18.1 (2026-11-24)

- First version of the template: Many Notes 0.18.1 (`brufdev/many-notes:0.18@sha256:4a61723eca842b644ced386b17e189d143e97096c65ac80eadca13c6cd89a739`).
- One service with a `/data` volume (SQLite, vault files, search index).
- Admin account created on the first boot from `ADMIN_EMAIL` and a generated `ADMIN_PASSWORD`. Open sign-up is off.
- Generated `APP_KEY` and `REVERB_APP_SECRET`. Typesense and Reverb listen on loopback only.
- Tuned for 0.5 GB services (Typesense memory, worker counts from the CPU limit).
