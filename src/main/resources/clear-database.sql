-- ============================================
-- CLEAR DATABASE: Drop all objects but keep the DB
-- ============================================
-- WARNING: This drops ALL tables, views, procedures, and functions!
-- Use this to start fresh without recreating the database.
-- After running this, you can re-run: mvn liquibase:update

-- Step 1: Disable all foreign key constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Step 2: Drop all foreign keys
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql += 'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.'
             + QUOTENAME(OBJECT_NAME(parent_object_id))
             + ' DROP CONSTRAINT ' + QUOTENAME(name) + ';'
FROM sys.foreign_keys;
EXEC sp_executesql @sql;

-- Step 3: Drop all tables (including DATABASECHANGELOG and DATABASECHANGELOGLOCK)
SET @sql = '';
SELECT @sql += 'DROP TABLE ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
EXEC sp_executesql @sql;

-- Step 4: Drop all views
SET @sql = '';
SELECT @sql += 'DROP VIEW ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';'
FROM INFORMATION_SCHEMA.VIEWS;
EXEC sp_executesql @sql;

-- Step 5: Drop all stored procedures
SET @sql = '';
SELECT @sql += 'DROP PROCEDURE ' + QUOTENAME(ROUTINE_SCHEMA) + '.' + QUOTENAME(ROUTINE_NAME) + ';'
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE';
EXEC sp_executesql @sql;

-- Step 6: Drop all functions
SET @sql = '';
SELECT @sql += 'DROP FUNCTION ' + QUOTENAME(ROUTINE_SCHEMA) + '.' + QUOTENAME(ROUTINE_NAME) + ';'
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION';
EXEC sp_executesql @sql;
