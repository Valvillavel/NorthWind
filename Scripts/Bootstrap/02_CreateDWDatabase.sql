/*
================================================================================
 Bootstrap Script — Step 2: Create NorthWindDW Database
 Script:    02_CreateDWDatabase.sql
================================================================================
*/
USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'NorthWindDW')
BEGIN
    CREATE DATABASE [NorthWindDW]
        COLLATE Latin1_General_CI_AS;
    PRINT 'Database NorthWindDW created.';
END
ELSE
    PRINT 'Database NorthWindDW already exists — skipping creation.';
GO

USE [NorthWindDW];
GO

-- ============================================================
-- Schemas
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC ('CREATE SCHEMA [staging] AUTHORIZATION [dbo]');
    PRINT 'Schema [staging] created.';
END
GO

PRINT 'NorthWindDW database and schemas ready.';
GO
