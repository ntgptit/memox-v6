# MemoX v6 database contract

Status: **Accepted baseline**

Owner: **Data / Platform**

Tier 1: **Web and Android**

Drift is the local source of truth. Both Tier-1 platforms share the schema and
repository contract in [`schema-v1.md`](./schema-v1.md) and the migration rules
in [`migration-policy.md`](./migration-policy.md). Platform openers are adapters;
they do not define business behavior.

## Non-negotiable boundaries

- Presentation -> use case -> repository port -> repository implementation -> DAO.
- UI/providers never call DAOs or platform openers.
- Domain code imports neither Drift nor Flutter.
- Transaction boundaries live in data/database/repository implementation code.
- SRS transition math has one source:
  `lib/domain/learning_progress/srs_8_box_policy.dart`.
- Instants use UTC. Local-day snapshots also store the timezone inputs required
  by Goal/Streak rules.
- Every retryable mutation has a stable idempotency key.

## Required evidence

The same DAO/repository contract suite runs for Web and Android openers. Schema,
migration, rollback, corruption, concurrency, restart, quota/low-storage, and
large-library fixtures are versioned and reproducible.
