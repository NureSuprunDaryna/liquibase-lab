# Liquibase Lab

## Project overview

This repository is used for Lab 3–5 on database state management with Liquibase. The team is building a **relational projection** of selected models from the existing platform. The source application is document-oriented, so for the lab we intentionally select and flatten the most important fields into SQL Server tables, define indexes for the main business queries, prepare seed data, then add denormalized fields and triggers in the next lab steps.

The selected domain is **volunteer collaboration management**. The database covers the core flow of the platform: users create organizations, organizations run projects, projects contain events and tasks, users participate in contexts through roles, and the system supports skill-based coordination.

## Team members and ownership

| Member | Role | Initial ownership |
|---|---|---|
| Darуna | Team Lead | `users`, `organizations` |
| Alyona | Developer | `skills`, `projects` |
| Mykyta | Developer | `events`, `project_tasks` |
| Danylo | Developer | `context_roles`, `participations` |

## Execution order

1. Darуna creates `users` and `organizations`.
2. Alyona pulls `main`, then creates `skills` and `projects`.
3. Mykyta pulls `main`, then creates `events` and `project_tasks`.
4. Danylo pulls `main`, then creates `context_roles` and `participations`.

Only after the full schema is merged into `main` does the team move to seed data, denormalization, and triggers.

## Repository rules

1. Never commit `src/main/resources/liquibase.properties` or `src/main/resources/liquibase-init-db.properties`.
2. Never work directly in `main`. Always create a feature branch.
3. Before any work, run `git pull origin main`.
4. Each new table must be defined in its own file in `src/main/resources/db/changelogs/init/`.
5. Each schema change after init must be defined in its own file in `src/main/resources/db/changelogs/changes/`.
6. Each seed-data file must be stored in `src/main/resources/db/changelogs/data/`.
7. Each trigger file must be stored in `src/main/resources/db/changelogs/triggers/`.
8. Every new changelog file must be added to `master-changelog.xml`.
9. Every new table must also be registered in `dbo.tables`.
10. Do not edit another member’s file unless the Team Lead explicitly approves it.
11. All changelog `author` values must use the member’s first name in lowercase: `daryna`, `alyona`, `mykyta`, `danylo`.
12. For data, change, and trigger files, use preconditions with `onFail="HALT"`.

## Naming conventions

- Table names: plural
- Primary keys: `id`
- Foreign keys: `<parent_table_singular>_id`
- Timestamps: `*_at`
- Booleans: `is_*`
- Changelog files:
  - init: `<table>-init.xml`
  - data: `<table>-data-v001.xml`
  - changes: `<table>-change-v001.xml`
  - triggers: `<table>-trigger-v001.xml`
- Index names:
  - `ux_<table>_<column>` for unique indexes
  - `ix_<table>_<column_list>` for non-unique indexes
  - `fk_<child>_<parent>` for foreign keys

## Technical setup for every team member

1. Clone the repository.
2. Create local copies of:
   - `src/main/resources/liquibase-init-db.properties.example` -> `liquibase-init-db.properties`
   - `src/main/resources/liquibase.properties.example` -> `liquibase.properties`
3. Set local SQL Server credentials.
4. Run:

```bash
mvn -Pinit-db liquibase:update
mvn liquibase:update
```

5. Make sure the database exists and the `tables` meta-table is created.

## Relational scope for the lab

The original models contain embedded objects and arrays such as `availability`, `socialLinks`, `requiredSkills`, `permissions`, `assignableBy`, `joinDates`, and `leaveEvents`. To keep the lab focused and consistent with the minimum required number of tables, those document-style structures are **not** included in the first relational version. The team uses a clean SQL subset of the models.

All domain tables use `UNIQUEIDENTIFIER` as the primary key. This makes cross-file seed data easier and avoids identity conflicts between team members.

---

## Table design

### 1. `users` — owner: Daryna

Purpose: stores platform users.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| google_id | NVARCHAR(100) | yes | external identity |
| first_name | NVARCHAR(100) | no | |
| last_name | NVARCHAR(100) | no | |
| email | NVARCHAR(255) | no | unique |
| password_hash | NVARCHAR(255) | no | |
| system_role_name | NVARCHAR(50) | no | default `User` |
| registered_at | DATETIME2 | no | default `SYSUTCDATETIME()` |
| google_verified | BIT | no | default `0` |
| google_verified_at | DATETIME2 | yes | |
| email_verified | BIT | no | default `0` |
| two_factor_enabled | BIT | no | default `0` |

Indexes:
- `pk_users`
- `ux_users_email` on `(email)`
- `ix_users_system_role_name_registered_at` on `(system_role_name, registered_at)`
- `ix_users_last_name_first_name` on `(last_name, first_name)`

### 2. `organizations` — owner: Daryna

Purpose: stores volunteer organizations.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| name | NVARCHAR(200) | no | |
| description | NVARCHAR(1000) | no | |
| owner_id | UNIQUEIDENTIFIER | no | FK -> `users.id` |
| created_at | DATETIME2 | no | default `SYSUTCDATETIME()` |
| launch_date | DATETIME2 | yes | |
| is_archived | BIT | no | default `0` |
| logo_url | NVARCHAR(500) | yes | |
| phone_number | NVARCHAR(50) | yes | |
| latitude | DECIMAL(9,6) | yes | flattened from location |
| longitude | DECIMAL(9,6) | yes | flattened from location |
| join_policy | NVARCHAR(50) | no | `open` / `approval_required` |
| leave_policy | NVARCHAR(50) | no | `open` / `approval_required` |

Indexes:
- `pk_organizations`
- `ix_organizations_owner_id` on `(owner_id)`
- `ix_organizations_is_archived_created_at` on `(is_archived, created_at)`
- `ix_organizations_name` on `(name)`
- `ix_organizations_latitude_longitude` on `(latitude, longitude)`

### 3. `skills` — owner: Alyona

Purpose: stores user skills. One user can have many skills.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| user_id | UNIQUEIDENTIFIER | no | FK -> `users.id` |
| name | NVARCHAR(150) | no | |
| description | NVARCHAR(1000) | yes | |
| icon_url | NVARCHAR(500) | yes | |

Indexes:
- `pk_skills`
- `ix_skills_user_id` on `(user_id)`
- `ux_skills_user_id_name` on `(user_id, name)`

### 4. `projects` — owner: Alyona

Purpose: stores projects that belong to organizations.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| title | NVARCHAR(200) | no | |
| description | NVARCHAR(2000) | no | |
| created_at | DATETIME2 | no | default `SYSUTCDATETIME()` |
| end_at | DATETIME2 | no | |
| organization_id | UNIQUEIDENTIFIER | no | FK -> `organizations.id` |
| latitude | DECIMAL(9,6) | yes | flattened from location |
| longitude | DECIMAL(9,6) | yes | flattened from location |
| is_archived | BIT | no | default `0` |
| join_policy | NVARCHAR(50) | no | |
| leave_policy | NVARCHAR(50) | no | |

Indexes:
- `pk_projects`
- `ix_projects_organization_id` on `(organization_id)`
- `ix_projects_organization_id_is_archived_end_at` on `(organization_id, is_archived, end_at)`
- `ix_projects_end_at` on `(end_at)`
- `ix_projects_latitude_longitude` on `(latitude, longitude)`

### 5. `events` — owner: Mykyta

Purpose: stores organization-level or project-level events.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| organization_id | UNIQUEIDENTIFIER | no | FK -> `organizations.id` |
| project_id | UNIQUEIDENTIFIER | yes | FK -> `projects.id` |
| title | NVARCHAR(200) | no | |
| description | NVARCHAR(2000) | no | |
| start_at | DATETIME2 | no | |
| end_at | DATETIME2 | no | |
| type | NVARCHAR(100) | yes | |
| latitude | DECIMAL(9,6) | yes | flattened from location |
| longitude | DECIMAL(9,6) | yes | flattened from location |
| is_cancelled | BIT | no | default `0` |
| cancelled_at | DATETIME2 | yes | |
| cancelled_by | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| cancel_reason | NVARCHAR(1000) | yes | |
| created_at | DATETIME2 | no | default `SYSUTCDATETIME()` |
| updated_at | DATETIME2 | yes | |
| join_policy | NVARCHAR(50) | no | |
| leave_policy | NVARCHAR(50) | no | |
| series_id | UNIQUEIDENTIFIER | yes | recurrence support |
| master_id | UNIQUEIDENTIFIER | yes | recurrence support |
| is_series_master | BIT | no | default `0` |
| occurrence_index | INT | no | default `0` |

Indexes:
- `pk_events`
- `ix_events_organization_id_start_at` on `(organization_id, start_at)`
- `ix_events_project_id_start_at` on `(project_id, start_at)`
- `ix_events_is_cancelled_start_at` on `(is_cancelled, start_at)`
- `ix_events_series_id_occurrence_index` on `(series_id, occurrence_index)`

### 6. `project_tasks` — owner: Mykyta

Purpose: stores tasks linked to a project or event.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| organization_id | UNIQUEIDENTIFIER | no | FK -> `organizations.id` |
| project_id | UNIQUEIDENTIFIER | yes | FK -> `projects.id` |
| event_id | UNIQUEIDENTIFIER | yes | FK -> `events.id` |
| title | NVARCHAR(200) | no | |
| description | NVARCHAR(2000) | no | |
| start_at | DATETIME2 | no | |
| end_at | DATETIME2 | no | |
| status | NVARCHAR(50) | no | `Pending`, `InProgress`, `Completed`, `Cancelled` |
| points | INT | no | |
| assigned_to_user_id | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| join_policy | NVARCHAR(50) | no | |
| leave_policy | NVARCHAR(50) | no | |
| board_order | BIGINT | no | |
| started_at | DATETIME2 | yes | |
| started_by_user_id | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| completed_at | DATETIME2 | yes | |
| completed_by_user_id | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| last_status_changed_at | DATETIME2 | yes | |
| last_status_changed_by_user_id | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| series_id | UNIQUEIDENTIFIER | yes | recurrence support |
| master_id | UNIQUEIDENTIFIER | yes | recurrence support |
| is_series_master | BIT | no | default `0` |
| occurrence_index | INT | no | default `0` |

Indexes:
- `pk_project_tasks`
- `ix_project_tasks_project_id_status_start_at` on `(project_id, status, start_at)`
- `ix_project_tasks_event_id_status_start_at` on `(event_id, status, start_at)`
- `ix_project_tasks_assigned_to_user_id_status` on `(assigned_to_user_id, status)`
- `ix_project_tasks_organization_id_status` on `(organization_id, status)`
- `ix_project_tasks_series_id_occurrence_index` on `(series_id, occurrence_index)`

### 7. `context_roles` — owner: Danylo

Purpose: stores reusable and context-specific roles for organizations, projects, events, and tasks.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| name | NVARCHAR(150) | no | |
| description | NVARCHAR(1000) | yes | |
| is_template | BIT | no | default `0` |
| template_source_id | UNIQUEIDENTIFIER | yes | self-reference or template link |
| is_system_generated | BIT | no | default `0` |
| is_default_for_join | BIT | no | default `0` |
| entity_type | NVARCHAR(50) | yes | `organization`, `project`, `event`, `task` |
| entity_id | UNIQUEIDENTIFIER | yes | polymorphic target |
| is_active | BIT | no | default `1` |
| archived_at | DATETIME2 | yes | |
| archive_reason | NVARCHAR(50) | yes | `none`, `manual`, `no_users`, `context_ended` |

Indexes:
- `pk_context_roles`
- `ix_context_roles_entity_type_entity_id_is_active_name` on `(entity_type, entity_id, is_active, name)`
- `ix_context_roles_is_template_is_active` on `(is_template, is_active)`
- `ix_context_roles_is_default_for_join` on `(is_default_for_join)`

### 8. `participations` — owner: Danylo

Purpose: stores user participation in organizations, projects, events, and tasks.

| Column | Type | Null | Notes |
|---|---|---|---|
| id | UNIQUEIDENTIFIER | no | PK |
| entity_type | NVARCHAR(50) | no | `organization`, `project`, `event`, `task` |
| entity_id | UNIQUEIDENTIFIER | no | polymorphic target |
| user_id | UNIQUEIDENTIFIER | no | FK -> `users.id` |
| role_id | UNIQUEIDENTIFIER | no | FK -> `context_roles.id` |
| status | NVARCHAR(50) | no | `Pending`, `Accepted`, `Rejected`, `Cancelled`, `Completed` |
| created_by | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| approved_by | UNIQUEIDENTIFIER | yes | FK -> `users.id` |
| decided_at | DATETIME2 | yes | |
| decision_comment | NVARCHAR(1000) | yes | |
| is_active | BIT | no | |

Indexes:
- `pk_participations`
- `ux_participations_entity_type_entity_id_user_id` on `(entity_type, entity_id, user_id)`
- `ix_participations_user_id_status_is_active` on `(user_id, status, is_active)`
- `ix_participations_role_id_status_is_active` on `(role_id, status, is_active)`
- `ix_participations_entity_type_entity_id_status` on `(entity_type, entity_id, status)`

---

## Foreign-key strategy

Use strict foreign keys only where the target table is stable and non-polymorphic:

- `organizations.owner_id -> users.id`
- `projects.organization_id -> organizations.id`
- `events.organization_id -> organizations.id`
- `events.project_id -> projects.id`
- `events.cancelled_by -> users.id`
- `project_tasks.organization_id -> organizations.id`
- `project_tasks.project_id -> projects.id`
- `project_tasks.event_id -> events.id`
- `project_tasks.assigned_to_user_id -> users.id`
- `project_tasks.started_by_user_id -> users.id`
- `project_tasks.completed_by_user_id -> users.id`
- `project_tasks.last_status_changed_by_user_id -> users.id`
- `participations.user_id -> users.id`
- `participations.role_id -> context_roles.id`

Do **not** create foreign keys for `context_roles.entity_id` and `participations.entity_id` because they are polymorphic references.

---

## Branches and first-wave deliverables

### Daryna — first example implementation

Branch: `feature/daryna-users-organizations-init`

Files:
- `init/users-init.xml`
- `init/organizations-init.xml`

Responsibilities:
- create both tables
- create indexes
- add FKs
- register both tables in `dbo.tables`
- add both files to `master-changelog.xml`
- test locally with `mvn liquibase:update`
- open PR to `main`

### Alyona

Branch: `feature/alyona-skills-projects-init`

Files:
- `init/skills-init.xml`
- `init/projects-init.xml`

### Mykyta

Branch: `feature/mykyta-events-project-tasks-init`

Files:
- `init/events-init.xml`
- `init/project-tasks-init.xml`

### Danylo

Branch: `feature/danylo-context-roles-participations-init`

Files:
- `init/context-roles-init.xml`
- `init/participations-init.xml`

---

## Seed-data phase

After all init files are merged, each member creates seed-data files for their own tables.

Recommended file names:
- `data/users-data-v001.xml`
- `data/organizations-data-v001.xml`
- `data/skills-data-v001.xml`
- `data/projects-data-v001.xml`
- `data/events-data-v001.xml`
- `data/project-tasks-data-v001.xml`
- `data/context-roles-data-v001.xml`
- `data/participations-data-v001.xml`

Recommended order:
1. users
2. organizations
3. skills
4. projects
5. events
6. project_tasks
7. context_roles
8. participations

---

## Denormalization plan for the next lab step

Denormalized fields are introduced only after the base schema and seed data are stable.

### Daryna

Target table: `organizations`

Add columns:
- `active_projects_count INT NOT NULL DEFAULT 0`
- `active_events_count INT NOT NULL DEFAULT 0`

Meaning:
- `active_projects_count` = number of non-archived projects in the organization
- `active_events_count` = number of non-cancelled events in the organization

### Alyona

Target table: `projects`

Add columns:
- `active_events_count INT NOT NULL DEFAULT 0`
- `active_tasks_count INT NOT NULL DEFAULT 0`

Meaning:
- `active_events_count` = number of non-cancelled events linked to the project
- `active_tasks_count` = number of tasks linked to the project where `status <> 'Cancelled'`

### Mykyta

Target table: `events`

Add columns:
- `tasks_total_count INT NOT NULL DEFAULT 0`
- `tasks_completed_count INT NOT NULL DEFAULT 0`

Meaning:
- `tasks_total_count` = all tasks linked to the event
- `tasks_completed_count` = tasks linked to the event with `status = 'Completed'`

### Danylo

Target tables:
- `users`
- `context_roles`

Add columns:
- `users.active_participations_count INT NOT NULL DEFAULT 0`
- `context_roles.active_members_count INT NOT NULL DEFAULT 0`

Meaning:
- `users.active_participations_count` = count of accepted active participations for the user
- `context_roles.active_members_count` = count of accepted active participations attached to the role

---

## Trigger plan

### Daryna

File:
- `triggers/organizations-trigger-v001.xml`

Triggers:
- `trg_projects_sync_organization_counts`
- `trg_events_sync_organization_counts`

Logic:
- AFTER INSERT, UPDATE, DELETE on `projects` and `events`
- collect affected `organization_id` values from `inserted` and `deleted`
- recalculate organization counts with a set-based update

### Alyona

File:
- `triggers/projects-trigger-v001.xml`

Triggers:
- `trg_events_sync_project_counts`
- `trg_project_tasks_sync_project_counts`

Logic:
- AFTER INSERT, UPDATE, DELETE on `events` and `project_tasks`
- recalculate counts only for affected `project_id` values
- ignore rows where `project_id IS NULL`

### Mykyta

File:
- `triggers/events-trigger-v001.xml`

Trigger:
- `trg_project_tasks_sync_event_counts`

Logic:
- AFTER INSERT, UPDATE, DELETE on `project_tasks`
- recalculate `tasks_total_count` and `tasks_completed_count`
- ignore rows where `event_id IS NULL`

### Danylo

File:
- `triggers/participations-trigger-v001.xml`

Triggers:
- `trg_participations_sync_user_counts`
- `trg_participations_sync_role_counts`

Logic:
- AFTER INSERT, UPDATE, DELETE on `participations`
- only accepted and active participations contribute to counts
- recalculate counts for affected `user_id` and `role_id`

---

## Validation checklist before opening a PR

- local branch is up to date with `main`
- changelog file names follow the agreed convention
- `author` is correct
- all tables are registered in `dbo.tables`
- all indexes and FKs are present
- `master-changelog.xml` contains the new include lines
- `mvn liquibase:validate` passes
- `mvn liquibase:update` passes on a clean local database
- rollback block exists where practical

