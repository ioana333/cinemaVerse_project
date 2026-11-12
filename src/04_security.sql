-- PROIECT ABD - CinemaVerse
-- 04 - Utilizatori, roluri si drepturi. Ruleaza ca sysadmin, dupa 03_views.sql. Re-rulabil.
-- Roluri:
--   role_admin     - administrare completa a bazei de date (db_owner)
--   role_manager   - manager cinema: citeste tot, gestioneaza programul (filme, proiectii), vede ierarhia, NU vede salariile
--   role_cashier   - casier: vinde/anuleaza bilete, inregistreaza clienti, citeste programul
--   role_customer  - aplicatia web/mobil: citeste catalogul si programul, isi scrie recenzii, cumpara bilete
--   role_analyst   - analist: doar citire pe vederile de raportare

USE master;
GO
-- 1. Login-uri (nivel server). Parolele sunt de test - de schimbat in productie.
IF SUSER_ID('cv_admin')   IS NOT NULL DROP LOGIN cv_admin;
IF SUSER_ID('cv_manager') IS NOT NULL DROP LOGIN cv_manager;
IF SUSER_ID('cv_cashier') IS NOT NULL DROP LOGIN cv_cashier;
IF SUSER_ID('cv_webapp')  IS NOT NULL DROP LOGIN cv_webapp;
IF SUSER_ID('cv_analyst') IS NOT NULL DROP LOGIN cv_analyst;
GO
CREATE LOGIN cv_admin   WITH PASSWORD = 'Admin#2026!cv',   CHECK_POLICY = OFF;
CREATE LOGIN cv_manager WITH PASSWORD = 'Manager#2026!cv', CHECK_POLICY = OFF;
CREATE LOGIN cv_cashier WITH PASSWORD = 'Cashier#2026!cv', CHECK_POLICY = OFF;
CREATE LOGIN cv_webapp  WITH PASSWORD = 'Webapp#2026!cv',  CHECK_POLICY = OFF;
CREATE LOGIN cv_analyst WITH PASSWORD = 'Analyst#2026!cv', CHECK_POLICY = OFF;
GO

USE CinemaVerse;
SET QUOTED_IDENTIFIER ON;
GO
-- 2. Utilizatori in baza de date (cate unul pentru fiecare login)
DROP USER IF EXISTS cv_admin;  DROP USER IF EXISTS cv_manager; DROP USER IF EXISTS cv_cashier;
DROP USER IF EXISTS cv_webapp; DROP USER IF EXISTS cv_analyst;
CREATE USER cv_admin   FOR LOGIN cv_admin   WITH DEFAULT_SCHEMA = dbo;
CREATE USER cv_manager FOR LOGIN cv_manager WITH DEFAULT_SCHEMA = dbo;
CREATE USER cv_cashier FOR LOGIN cv_cashier WITH DEFAULT_SCHEMA = dbo;
CREATE USER cv_webapp  FOR LOGIN cv_webapp  WITH DEFAULT_SCHEMA = dbo;
CREATE USER cv_analyst FOR LOGIN cv_analyst WITH DEFAULT_SCHEMA = dbo;
GO

-- 3. Roluri
CREATE ROLE role_admin;
CREATE ROLE role_manager;
CREATE ROLE role_cashier;
CREATE ROLE role_customer;
CREATE ROLE role_analyst;
GO
ALTER ROLE role_admin    ADD MEMBER cv_admin;
ALTER ROLE role_manager  ADD MEMBER cv_manager;
ALTER ROLE role_cashier  ADD MEMBER cv_cashier;
ALTER ROLE role_customer ADD MEMBER cv_webapp;
ALTER ROLE role_analyst  ADD MEMBER cv_analyst;
GO

-- 4. Drepturi
-- 4.1 role_admin: control total pe baza de date (inclusiv DDL)
ALTER ROLE db_owner ADD MEMBER role_admin;
GO

-- 4.2 role_manager: citire, scriere pe program / catalog; ierarhia angajatilor doar prin vedere (fara salarii)
GRANT SELECT ON SCHEMA::dbo TO role_manager;
DENY  SELECT ON dbo.Employees TO role_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.Movies      TO role_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.Genres      TO role_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.MovieGenres TO role_manager;
GRANT INSERT, UPDATE, DELETE ON dbo.Screenings  TO role_manager;
GRANT UPDATE ON dbo.Tickets (status)            TO role_manager;    -- poate anula bilete, nu poate schimba pretul
GO

-- 4.3 role_cashier: citeste programul, vinde bilete, inregistreaza clienti
GRANT SELECT ON dbo.vw_UpcomingScreenings TO role_cashier;
GRANT SELECT ON dbo.vw_MovieCatalog       TO role_cashier;
GRANT SELECT ON dbo.vw_CustomerPublic     TO role_cashier;
GRANT SELECT, INSERT ON dbo.Tickets       TO role_cashier;
GRANT UPDATE ON dbo.Tickets (status)      TO role_cashier;          -- doar statusul (RESERVED -> PAID / CANCELLED)
GRANT INSERT ON dbo.Customers             TO role_cashier;          -- inscrie clienti noi
GRANT SELECT (customer_id, first_name, last_name, loyalty_points) ON dbo.Customers TO role_cashier;
DENY  DELETE ON dbo.Tickets               TO role_cashier;
DENY  SELECT ON dbo.Employees             TO role_cashier;
GO

-- 4.4 role_customer (aplicatia web/mobil): catalog + program, recenzii, cumparare bilete
GRANT SELECT ON dbo.vw_UpcomingScreenings TO role_customer;
GRANT SELECT ON dbo.vw_MovieCatalog       TO role_customer;
GRANT SELECT ON dbo.vw_CustomerTickets    TO role_customer;         -- aplicatia filtreaza dupa clientul autentificat
GRANT SELECT ON dbo.Cinemas               TO role_customer;
GRANT SELECT ON dbo.Genres                TO role_customer;
GRANT SELECT, INSERT, UPDATE ON dbo.Reviews TO role_customer;
GRANT INSERT ON dbo.Customers             TO role_customer;         -- creare cont
GRANT INSERT ON dbo.Tickets               TO role_customer;
DENY  SELECT ON dbo.Employees             TO role_customer;
DENY  UPDATE, DELETE ON dbo.Tickets       TO role_customer;
GO

-- 4.5 role_analyst: doar vederile de raportare, fara date personale
GRANT SELECT ON dbo.vw_Revenue            TO role_analyst;
GRANT SELECT ON dbo.vw_MovieCatalog       TO role_analyst;
GRANT SELECT ON dbo.vw_UpcomingScreenings TO role_analyst;
GRANT SELECT ON dbo.vw_CustomerPublic     TO role_analyst;
DENY  SELECT ON dbo.Employees TO role_analyst;
DENY  SELECT ON dbo.Customers TO role_analyst;
GO

-- 5. Verificare: membrii rolurilor si drepturile acordate
SELECT r.name AS rol, m.name AS membru
FROM sys.database_role_members rm
JOIN sys.database_principals r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
WHERE m.name LIKE 'cv[_]%' ORDER BY r.name;

SELECT dp.name AS rol, p.state_desc, p.permission_name,
       OBJECT_NAME(p.major_id) AS obiect, COL_NAME(p.major_id, p.minor_id) AS coloana
FROM sys.database_permissions p
JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
WHERE dp.name LIKE 'role[_]%' AND p.class IN (0,1,3)
ORDER BY dp.name, obiect, p.permission_name;
GO

-- 6. Teste (EXECUTE AS): cate un drept permis si unul refuzat
EXECUTE AS USER = 'cv_cashier';
    SELECT TOP 3 title, start_time, free_seats FROM vw_UpcomingScreenings ORDER BY start_time;   -- permis
    BEGIN TRY SELECT salary FROM Employees; END TRY
    BEGIN CATCH SELECT 'cashier -> Employees: ' + ERROR_MESSAGE() AS refuzat; END CATCH
REVERT;

EXECUTE AS USER = 'cv_manager';
    BEGIN TRY SELECT salary FROM Employees; END TRY
    BEGIN CATCH SELECT 'manager -> Employees: ' + ERROR_MESSAGE() AS refuzat; END CATCH
REVERT;

EXECUTE AS USER = 'cv_analyst';
    SELECT * FROM vw_Revenue ORDER BY revenue DESC;                                  -- permis
    BEGIN TRY DELETE FROM Tickets; END TRY
    BEGIN CATCH SELECT 'analyst -> DELETE Tickets: ' + ERROR_MESSAGE() AS refuzat; END CATCH
REVERT;
GO
