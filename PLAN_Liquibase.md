# Liquibase Delivery Plan

## Objective

Build and document a relational SQL Server schema for the domain using Liquibase, then extend it with seed data, denormalized fields, and triggers.

## Scope

Selected tables:
- `users`
- `organizations`
- `skills`
- `projects`
- `events`
- `project_tasks`
- `context_roles`
- `participations`

## Phase 1 — Environment setup

Owner: everyone

Steps:
1. Clone the repository.
2. Create local Liquibase property files from `.example` files.
3. Configure SQL Server credentials.
4. Run:

```bash
mvn -Pinit-db liquibase:update
mvn liquibase:update
```

5. Confirm that the database is available locally.

## Phase 2 — Base schema implementation

### Step 2.1 — Daryna (example first)

Branch: `feature/daryna-users-organizations-init`

Deliverables:
- `users-init.xml`
- `organizations-init.xml`
- includes in `master-changelog.xml`

### Step 2.2 — Alyona

Precondition:
- Darina’s branch is merged to `main`

Branch: `feature/alyona-skills-projects-init`

Deliverables:
- `skills-init.xml`
- `projects-init.xml`

### Step 2.3 — Mykyta

Precondition:
- Alyona’s branch is merged to `main`

Branch: `feature/mykyta-events-project-tasks-init`

Deliverables:
- `events-init.xml`
- `project-tasks-init.xml`

### Step 2.4 — Danylo

Precondition:
- Mykyta’s branch is merged to `main`

Branch: `feature/danylo-context-roles-participations-init`

Deliverables:
- `context-roles-init.xml`
- `participations-init.xml`

## Phase 3 — Seed data

Recommended order:
1. Daryna inserts users and organizations.
2. Alyona inserts skills and projects.
3. Mykyta inserts events and project tasks.
4. Danylo inserts context roles and participations.

Expected result:
- the schema is queryable and ready for screenshots, demo queries, and later denormalization

## Phase 4 — Denormalization

### Daryna
- add `organizations.active_projects_count`
- add `organizations.active_events_count`

### Alyona
- add `projects.active_events_count`
- add `projects.active_tasks_count`

### Mykyta
- add `events.tasks_total_count`
- add `events.tasks_completed_count`

### Danylo
- add `users.active_participations_count`
- add `context_roles.active_members_count`

## Phase 5 — Triggers

### Daryna
- trigger set for organization-level counters

### Alyona
- trigger set for project-level counters

### Mykyta
- trigger set for event-level counters

### Danylo
- trigger set for user and role counters

## Phase 6 — Reporting assets

Collect:
- repository link
- team responsibility table
- ER diagram
- database table diagram
- screenshots of `dbo.tables`
- screenshots of `DATABASECHANGELOG`
- list of changelog files created by each member
- concise explanation of denormalization and trigger logic

## Merge rules

1. One member works on one wave at a time.
2. No parallel edits of the same changelog file.
3. `master-changelog.xml` is merged only after local validation.
4. Every PR must include a short description of what was created and tested.

## Definition of done for each member

A task is complete only when:
- changelog files are created
- indexes are created
- required foreign keys are created
- metadata is written into `dbo.tables`
- include lines are added
- local update succeeds
- PR is reviewed and merged
