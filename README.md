# Accounting

A personal double-entry accounting app: track accounts, journal transactions,
and reconcile against bank/card statements, with Balance Sheet, Income
Statement, and Cash Flow Statement reports. Supports multiple independent
workspaces (e.g. "Personal" vs "Business"), each with its own chart of
accounts and transaction history.

## Requirements

- Ruby 3.3.0 (see `.ruby-version`)
- Node.js and Yarn (for building JS/CSS)
- SQLite 3

## Setup

```
bin/setup
```

This installs gem and JS dependencies, prepares the database, and starts the
dev server. To skip starting the server:

```
bin/setup --skip-server
```

## Running the app

```
bin/dev
```

Starts the Rails server plus JS/CSS watchers (via `Procfile.dev`), and the
app is available at http://localhost:3000.

## Running tests

```
bin/rails test
```

## Database

Uses SQLite; the development database lives under `storage/` and isn't
checked into git (see `.gitignore`), so your financial data stays local.
Each workspace shares the same database but data is scoped by a
`workspace_id` column — see `app/models/concerns/workspace_scoped.rb`.
