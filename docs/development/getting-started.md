# Development setup

Copy `.env.example` to `.env`, replace the database password, and install the toolchains listed in the root README. Use `docker compose up postgres` when developing the API locally, or `docker compose up --build` for the containerized API.

The root `goshipkit.sql` is a fresh-install bootstrap schema. Once release migrations begin, do not edit an applied migration; add a new numbered migration under `server/migrations`.
