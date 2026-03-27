-- ============================================
-- DROP DATABASE: Completely remove the database
-- ============================================
-- WARNING: This PERMANENTLY DELETES the entire database!
-- You will need to recreate it manually before running migrations again.

USE master;
GO

-- Kill all active connections to the database
DECLARE @kill VARCHAR(8000) = '';
SELECT @kill = @kill + 'KILL ' + CONVERT(VARCHAR(5), session_id) + ';'
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('liquibase_lab');
EXEC(@kill);
GO

-- Drop the database (no turning back!)
DROP DATABASE liquibase_lab;
GO
