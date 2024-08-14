/*
USE mine;
GO
DROP DATABASE NewDB;
*/
CREATE DATABASE NewDB;
GO
USE NewDB;
GO
SET NOCOUNT OFF
DROP TABLE IF EXISTS _tb_tasks_users
GO
DROP TABLE IF EXISTS _tb_tasks
GO
DROP TABLE IF EXISTS _tb_users_managers
GO
DROP TABLE IF EXISTS _tb_users
GO
DROP TABLE IF EXISTS _tb_tenants
GO
DROP TABLE IF EXISTS _tb_priorities
GO
DROP TABLE IF EXISTS _tb_status
GO
DROP PROCEDURE IF EXISTS dbo._sp_show_tasks
GO
DROP TABLE IF EXISTS _tb_tasks_histo 
GO
DROP INDEX IF EXISTS idx_tasks_histo_tenant ON _tb_tasks_histo
GO
DROP INDEX IF EXISTS idx_tasks_tenant ON _tb_tasks
GO
DROP PROCEDURE IF EXISTS dbo._sp_delete_task
GO
DROP PROCEDURE IF EXISTS dbo._sp_update_task
GO
DROP FUNCTION IF EXISTS dbo.udfTasksSecurity
GO
DROP PROCEDURE IF EXISTS dbo._sp_create_task
GO
DROP PROCEDURE IF EXISTS dbo._sp_manager_statistics
GO
CREATE TABLE _tb_tenants (
	id_tenant INT IDENTITY(1,1) PRIMARY KEY,
	tenant_name NVARCHAR(max)
)
GO
CREATE TABLE _tb_users (
	id_user INT IDENTITY(1,1) PRIMARY KEY,
	id_tenant INT FOREIGN KEY REFERENCES _tb_tenants(id_tenant) ON DELETE CASCADE,
	email NVARCHAR(max),
	is_manager BIT,
	[password] NVARCHAR(max),
	first_name NVARCHAR(max),
	last_name NVARCHAR(max)
)
GO
CREATE TABLE _tb_users_managers (
	id_user_manager INT IDENTITY(1,1) PRIMARY KEY,
	id_manager INT FOREIGN KEY REFERENCES _tb_users(id_user),
	id_user INT FOREIGN KEY REFERENCES _tb_users(id_user), --CONSTRAINT CHK_id_user__tb_users_managers CHECK (id_user <> id_manager)
	id_tenant INT FOREIGN KEY REFERENCES _tb_tenants(id_tenant)
)
GO
CREATE TABLE _tb_status (
	id_status TINYINT IDENTITY(1,1) PRIMARY KEY,
	[name] NVARCHAR(50)
)
GO
INSERT INTO _tb_status([name])
SELECT [name] FROM
(
	SELECT 'Nowe' as [name] UNION ALL
	SELECT 'W realizcji' as [name] UNION ALL
	SELECT 'Zakoñczone' as [name]
) tb
GO
CREATE TABLE _tb_priorities (
	id_priority TINYINT IDENTITY(1,1) PRIMARY KEY,
	[name] NVARCHAR(50)
)
GO
INSERT INTO _tb_priorities([name])
SELECT [name] FROM
(
	SELECT 'niski' as [name] UNION ALL
	SELECT 'œredni' as [name] UNION ALL
	SELECT 'wysoki' as [name]
) tb
GO
CREATE TABLE _tb_tasks (
	id_task BIGINT IDENTITY(1,1) PRIMARY KEY,
	created_by INT FOREIGN KEY REFERENCES _tb_users(id_user),
	created_on DATETIME,
	header NVARCHAR(max),
	[description] NVARCHAR(max),
	id_priority TINYINT FOREIGN KEY REFERENCES _tb_priorities(id_priority) ,
	id_tenant INT FOREIGN KEY REFERENCES _tb_tenants(id_tenant),
	id_status TINYINT FOREIGN KEY REFERENCES _tb_status(id_status),
	
)
GO
CREATE TABLE _tb_tasks_histo (
	id_histo BIGINT IDENTITY(1,1) PRIMARY KEY,
	id_task BIGINT,
	created_by INT,
	created_on DATETIME,
	header NVARCHAR(max),
	[description] NVARCHAR(max),
	id_priority TINYINT,
	id_tenant INT,
	id_status TINYINT,
	date_histo DATETIME,
	id_user_histo INT,
	[action] NVARCHAR(3)
)
GO
CREATE TABLE _tb_tasks_users (
	id_task_user INT IDENTITY(1,1) PRIMARY KEY,
	id_user INT  FOREIGN KEY REFERENCES _tb_users(id_user),
	id_task BIGINT FOREIGN KEY REFERENCES _tb_tasks(id_task) ON DELETE CASCADE,
	id_tenant INT FOREIGN KEY REFERENCES _tb_tenants(id_tenant)
)

GO

--BEGIN TRAN
-- Populate _tb_tenants 
DECLARE @i INT = 1
WHILE @i < 11
BEGIN
	INSERT INTO _tb_tenants(tenant_name)
	SELECT CONCAT('tenant_', @i)
	SET @i = @i + 1
END;
--SELECT * FROM _tb_tenants

GO 

-- Populate _tb_users 
DECLARE @i INT = 1, @x INT = 1
WHILE @x < 11

	BEGIN
		SET @i = 1
		WHILE @i < 101
			BEGIN
				INSERT INTO _tb_users(id_tenant, email, is_manager, [password], first_name, last_name)
				SELECT 
					--FLOOR(RAND() * 10) + 1 as id_tenant -- random number from 1 to 10
					@x as id_tenant
					, CONCAT('firstname', @i, '.lastname', @i, '@tenant', @x, '.com') as email
					, CASE CAST((FLOOR(RAND() * 10) + 1) as INT) % 10 --around every 10th employee is a manager
						WHEN 0 THEN 1
						ELSE 0
					END as is_manager
					,'123' as [password]
					,CONCAT('firstname', @i) as first_name
					,CONCAT('lastname', @i) as last_name
				SET @i = @i + 1
			END;
		SET @x = @x + 1
	END;
--SELECT * FROM _tb_users

GO
-- Populate _tb_users_managers
DECLARE @i INT = 1, @id_manager INT
WHILE @i < 11
BEGIN 

	WHILE EXISTS (
		SELECT 1
			--tu.id_user
			--,tu.id_tenant
			--,COUNT(tum.id_user) AS nm_employees_under_manager
		FROM
			_tb_users tu
		LEFT JOIN
			_tb_users_managers tum
				ON tu.id_user = tum.id_manager
				AND tu.id_tenant = tum.id_tenant
		WHERE 
			tu.is_manager = 1
			AND tu.id_tenant = @i --parameter here
		GROUP BY
			tu.id_user
			,tu.id_tenant
		HAVING
			COUNT(tum.id_user) < 3
	)
	BEGIN

	SET @id_manager = (
		SELECT TOP 1
			tu.id_user
		FROM
			_tb_users tu
		LEFT JOIN
			_tb_users_managers tum
				ON tu.id_user = tum.id_manager
				AND tu.id_tenant = tum.id_tenant
		WHERE 
			tu.is_manager = 1
			AND tu.id_tenant = @i --parameter here
		GROUP BY
			tu.id_user
			,tu.id_tenant
		HAVING
			COUNT(tum.id_user) < 3
		)

		INSERT INTO _tb_users_managers(id_user, id_manager, id_tenant)
		SELECT TOP 3
			tu.id_user, 
			@id_manager, 
			@i
		FROM
			_tb_users tu
		WHERE
			tu.is_manager = 0
			AND tu.id_tenant = @i --parameter here
			AND NOT EXISTS (SELECT 1 FROM _tb_users_managers tum WHERE tum.id_user = tu.id_user and tum.id_tenant = tu.id_tenant)
	
	END;
		SET @i = @i + 1


END;
--SELECT * FROM _tb_users_managers


GO


-- Populate _tb_tasks
--BEGIN TRAN
SET NOCOUNT ON

-- declare variables used in cursor and date randomizer
DECLARE @id_user INT, @i INT = 1, @StartDate DATE = '01/01/2024', @EndDate DATE = '12/08/2024';
 
-- declare cursor
DECLARE cursor_id_user CURSOR FOR
  SELECT TOP 1000 id_user
  FROM _tb_users
  ORDER BY 1
-- open cursor
OPEN cursor_id_user;
 
-- loop through a cursor
FETCH NEXT FROM cursor_id_user INTO @id_user;
WHILE @@FETCH_STATUS = 0
    BEGIN
	SET @i = 1
	WHILE @i < 1001
	BEGIN
		INSERT INTO _tb_tasks(
			created_by
			, created_on
			, header
			, [description]
			, id_priority
			, id_tenant
			, id_status
			)
		SELECT 
			id_user AS created_by
			,CAST(DATEADD(DAY, RAND(CHECKSUM(NEWID()))*(1+DATEDIFF(DAY, @StartDate, @EndDate)),@StartDate) AS DATETIME) AS created_on
			,CONCAT('Zadanie nr ', @i) AS header
			,'Opis Zadania' as [description]
			, ROUND(RAND() * (3-1) + 1, 0) as id_priority
			, id_tenant 
			, ROUND(RAND() * (3-1) + 1, 0) as id_status
		FROM _tb_users
		WHERE id_user = @id_user;

		SET @i = @i + 1
	END;
    --PRINT CONCAT('tasks created for user id: ', @id_user);
    FETCH NEXT FROM cursor_id_user INTO @id_user;
    END;
 
-- close and deallocate cursor
CLOSE cursor_id_user;
DEALLOCATE cursor_id_user;




--SELECT * FROM _tb_tasks

GO
CREATE INDEX idx_tasks_histo_tenant
ON _tb_tasks_histo (id_tenant, id_task);
GO
CREATE INDEX idx_tasks_tenant
ON _tb_tasks (id_tenant, id_task);
GO
--Populate _tb_tasks_users
DECLARE 
	@id_task INT
	, @id_user_created INT
	, @id_tenant INT
	, @i INT = 1
WHILE @i < 1001
BEGIN
	SELECT 
		@id_task = id_task
		, @id_user_created = created_by
		, @id_tenant = id_tenant
	FROM 
		_tb_tasks
	WHERE
		id_task = ROUND(RAND() * (1000000 - 1) + 1, 0)

	INSERT INTO _tb_tasks_users(
		id_user
		, id_task
		, id_tenant
	)
	SELECT TOP 5 
		id_user
		, @id_task
		, id_tenant
	FROM 
		_tb_users
	WHERE 
		id_tenant = @id_tenant AND 
		id_user != @id_user_created
	ORDER BY 
		NEWID()

	SET @i = @i + 1
END;
--SELECT * FROM _tb_tasks_users

GO

CREATE PROCEDURE dbo._sp_show_tasks(
	@id_user INT
)
/*
	Procedure created to return available tasks and info about them per user
	Change log 
		(1) 2024-08-12 - Mateusz Paluch - Creation
*/
AS
BEGIN
	DECLARE 
		@id_tenant INT = (SELECT TOP 1 id_tenant FROM _tb_users WHERE id_user = @id_user)
		, @is_manager BIT = (SELECT TOP 1 is_manager FROM _tb_users WHERE id_user = @id_user)
	IF @is_manager = 0
	BEGIN
		SELECT 
			tt.header AS [Naglowek]
			,tt.[description] AS [Opis]
			,tt.created_on AS [Data]
			,CONCAT(tu.first_name, ' ', tu.last_name) AS [Zadanie za³ozone przez]
			,tp.[name] AS [Priorytet]
			,ts.[name] AS [Status]
		FROM
			_tb_tasks tt
		LEFT JOIN
			_tb_priorities tp
				ON tp.id_priority = tt.id_priority
		LEFT JOIN
			_tb_status ts
				ON ts.id_status = tt.id_status
		LEFT JOIN 
			_tb_users tu
				ON tu.id_user = tt.created_by
		WHERE 
			(tt.id_tenant = @id_tenant
			AND tt.created_by = @id_user)
			OR EXISTS(SELECT 1 FROM _tb_tasks_users ttu WHERE ttu.id_user = @id_user and ttu.id_task = tt.id_task)
	END;
	ELSE
	BEGIN
		;WITH cte_users_under_managers AS
		(
			SELECT 
				id_user
			FROM
				_tb_users_managers
			WHERE 
				id_manager = @id_user
		), cte_users_tasks AS
		(
			SELECT 
				tt.id_task
			FROM 
				_tb_tasks tt
			WHERE EXISTS (SELECT 1 FROM cte_users_under_managers cte WHERE cte.id_user = tt.created_by)
		)
		SELECT 
			tt.header AS [Nag³ówek]
			,tt.[description] AS [Opis]
			,tt.created_on AS [Data]
			,CONCAT(tu.first_name, ' ', tu.last_name) AS [Zadanie za³o¿one przez]
			,tp.[name] AS [Priorytet]
			,ts.[name] AS [Status]
		FROM
			_tb_tasks tt
		LEFT JOIN
			_tb_priorities tp
				ON tp.id_priority = tt.id_priority
		LEFT JOIN
			_tb_status ts
				ON ts.id_status = tt.id_status
		LEFT JOIN 
			_tb_users tu
				ON tu.id_user = tt.created_by
		WHERE 
			tt.id_tenant = @id_tenant
			AND EXISTS (SELECT 1 FROM cte_users_tasks cte WHERE cte.id_task = tt.id_task) 
			
		UNION ALL

		SELECT 
			tt.header AS [Nag³ówek]
			,tt.[description] AS [Opis]
			,tt.created_on AS [Data]
			,CONCAT(tu.first_name, ' ', tu.last_name) AS [Zadanie za³o¿one przez]
			,tp.[name] AS [Priorytet]
			,ts.[name] AS [Status]
		FROM
			_tb_tasks tt
		LEFT JOIN
			_tb_priorities tp
				ON tp.id_priority = tt.id_priority
		LEFT JOIN
			_tb_status ts
				ON ts.id_status = tt.id_status
		LEFT JOIN 
			_tb_users tu
				ON tu.id_user = tt.created_by
		WHERE 
			(tt.id_tenant = @id_tenant
			AND tt.created_by = @id_user)
			OR EXISTS(
			SELECT 1 FROM _tb_tasks_users ttu WHERE ttu.id_user = @id_user and ttu.id_task = tt.id_task
			)
	END;
END;
GO

CREATE FUNCTION [dbo].[udfTasksSecurity](
	@id_tenant TINYINT,
	@id_user INT,
	@id_task BIGINT
)
/*
	Function created to return available to a regular employee tasks
	Change log:
		(1) Creation - 2024-08-14 - Mateusz Paluch
*/
RETURNS TABLE
AS
RETURN 

WITH cte_tt AS
(
	SELECT * FROM _tb_tasks WHERE id_tenant = @id_tenant AND id_task = @id_task
)
(
	SELECT 
		tt.id_task
	FROM
		cte_tt tt
	LEFT JOIN
		_tb_priorities tp
			ON tp.id_priority = tt.id_priority
	LEFT JOIN
		_tb_status ts
			ON ts.id_status = tt.id_status
	LEFT JOIN 
		_tb_users tu
			ON tu.id_user = tt.created_by
	WHERE 
		(tt.id_tenant = @id_tenant
		AND tt.created_by = @id_user)
		OR EXISTS (SELECT 1 FROM _tb_tasks_users ttu WHERE ttu.id_user = @id_user and ttu.id_task = tt.id_task)
 )
 GO

CREATE PROCEDURE dbo._sp_delete_task(
	@id_user INT,
	@id_task BIGINT
)
AS
/*
	Procedure created to allow user delete his tasks, security applied in case user tries delete not his task
	Change log:
		(1) 2024-08-14 - Mateusz Paluch - Creation
*/
BEGIN

DECLARE 
	@id_tenant INT = (SELECT TOP 1 id_tenant FROM _tb_users WHERE id_user = @id_user)	
	IF EXISTS (SELECT TOP 1 '1' FROM [dbo].[udfTasksSecurity](@id_tenant,@id_user,@id_task)) -- check if the user is allowed to update the task

	BEGIN 
	INSERT INTO _tb_tasks_histo(
		id_task
		,created_by
		,created_on
		,header
		,[description]
		,id_priority
		,id_tenant
		,id_status
		,date_histo
		,id_user_histo
		,[action]
	)
	SELECT 
		id_task
		,created_by
		,created_on
		,header
		,description
		,id_priority
		,id_tenant
		,id_status
		,GETDATE()
		,@id_user
		,'del'
	FROM 
		_tb_tasks
	WHERE
		id_tenant = @id_tenant
		and id_task = @id_task
	DELETE
		_tb_tasks
	WHERE
		id_tenant = @id_tenant
		and id_task = @id_task
	END;

	ELSE
	BEGIN
		PRINT('Nie mo¿esz usun¹æ tego zadania lub zadanie nie istnieje')
	END;
END;
GO
CREATE PROCEDURE dbo._sp_update_task (
	@id_user INT
	,@id_task BIGINT
	,@new_header NVARCHAR(50) = NULL
	,@new_description NVARCHAR(MAX) = NULL
	,@new_priority NVARCHAR(50) = NULL
	,@new_status NVARCHAR(50) = NULL
)
AS
/*
	Procedure created to allow user to update existing tasks, error handling and security applied
	Change log:
		(1) 2024-08-14 - Mateusz Paluch - Creation
*/
BEGIN
	DECLARE 
		@id_tenant INT = (SELECT TOP 1 id_tenant FROM _tb_users WHERE id_user = @id_user)	
		,@msg NVARCHAR(MAX)
		,@new_id_priority TINYINT = (SELECT TOP 1 id_priority FROM _tb_priorities WHERE [name] = @new_priority)
		,@new_id_status TINYINT = (SELECT TOP 1 id_status FROM _tb_status WHERE [name] = @new_status);


	IF 	@new_header IS NULL AND @new_description IS NULL AND @new_priority IS NULL AND @new_status IS NULL
	BEGIN
		SET @msg = 'Nie wprowadzi³eœ/aœ ¿adnej nowej wartoœci, do edycji nie dosz³o'
		PRINT @msg	
		RETURN
	END;
	IF EXISTS (SELECT TOP 1 '1' FROM [dbo].[udfTasksSecurity](@id_tenant,@id_user,@id_task)) -- check if the user is allowed to update the task
	BEGIN 
		IF @new_header IS NOT NULL AND (SELECT LEN(@new_header)) > 50
		BEGIN
			SET @msg = 'Nowy nag³ówek mo¿e byæ tylko d³ugi na 50 znaków, proszê skróæ nag³ówek i spróbuj ponownie. 
				Edycja nieudana'
			PRINT @msg
			RETURN
		END;
		IF @new_priority IS NOT NULL AND NOT EXISTS (SELECT name FROM _tb_priorities tp WHERE tp.name = @new_priority)
		BEGIN
			SET @msg = (SELECT CONCAT('Taki priorytet nie istnieje, akceptowalne priorytety to: ',(SELECT STRING_AGG([name], ', ') FROM _tb_priorities), '
				Edycja nieudana'))
			PRINT @msg
			RETURN
		END;
		IF @new_status IS NOT NULL AND NOT EXISTS (SELECT name FROM _tb_status tp WHERE tp.name = @new_status)
		BEGIN
			SET @msg = (SELECT CONCAT('Taki status nie istnieje, akceptowalne statusy to: ',(SELECT STRING_AGG([name], ', ') FROM _tb_status), '
				Edycja nieudana'))
			PRINT @msg
			RETURN
		END;

		INSERT INTO _tb_tasks_histo(
			id_task
			,created_by
			,created_on
			,header
			,[description]
			,id_priority
			,id_tenant
			,id_status
			,date_histo
			,id_user_histo
			,[action]
		)
		SELECT 
			id_task
			,created_by
			,created_on
			,ISNULL(@new_header,header)
			,ISNULL(@new_description,[description])
			,ISNULL(@new_id_priority,id_priority)
			,id_tenant
			,ISNULL(@new_id_status,id_status)
			,GETDATE()
			,@id_user
			,'upd'
		FROM 
			_tb_tasks
		WHERE
			id_tenant = @id_tenant
			AND id_task = @id_task

		UPDATE 
			_tb_tasks
		SET
			header = ISNULL(@new_header,header)
			,[description] = ISNULL(@new_description,[description])
			,id_priority = ISNULL(@new_id_priority,id_priority)
			,id_status = ISNULL(@new_id_status,id_status)
		WHERE
			id_tenant = @id_tenant
			AND id_task = @id_task

	END;
	ELSE
	BEGIN
		PRINT 'Nie mo¿esz edytowaæ tego zadania lub zadanie nie istnieje'
		RETURN
	END;
END;
GO
CREATE PROCEDURE dbo._sp_create_task (
	@id_user INT
	,@header NVARCHAR(50)
	,@description NVARCHAR(MAX)
	,@priority NVARCHAR(50)
	,@status NVARCHAR(50)
)
/*
	Procedure created to enable user creating new tasks
	Change log:
		(1) 2024-08-14 - Mateusz Paluch - Creation
*/
AS
BEGIN
	DECLARE 
		@id_tenant INT = (SELECT TOP 1 id_tenant FROM _tb_users WHERE id_user = @id_user)	
		,@msg NVARCHAR(MAX)
		,@id_priority TINYINT = (SELECT TOP 1 id_priority FROM _tb_priorities WHERE [name] = @priority)
		,@id_status TINYINT = (SELECT TOP 1 id_status FROM _tb_status WHERE [name] = @status);

		IF (SELECT LEN(@header)) > 50
		BEGIN
			SET @msg = 'Nag³ówek mo¿e byæ tylko d³ugi na 50 znaków, proszê skróæ nag³ówek i spróbuj ponownie. 
				Utwrzenie zadania nie powiod³o siê'
			PRINT @msg
			RETURN
		END;
		IF NOT EXISTS (SELECT name FROM _tb_priorities tp WHERE tp.name = @priority)
		BEGIN
			SET @msg = (SELECT CONCAT('Taki priorytet nie istnieje, akceptowalne priorytety to: ',(SELECT STRING_AGG([name], ', ') FROM _tb_priorities), '
				Utwrzenie zadania nie powiod³o siê'))
			PRINT @msg
			RETURN
		END;
		IF NOT EXISTS (SELECT name FROM _tb_status tp WHERE tp.name = @status)
		BEGIN
			SET @msg = (SELECT CONCAT('Taki status nie istnieje, akceptowalne statusy to: ',(SELECT STRING_AGG([name], ', ') FROM _tb_status), '
				Utwrzenie zadania nie powiod³o siê'))
			PRINT @msg
			RETURN
		END;

		INSERT INTO _tb_tasks(
			created_by
			,created_on
			,header
			,[description]
			,id_priority
			,id_tenant
			,id_status
		)
		SELECT 
			@id_user
			,GETDATE()
			,@header
			,@description
			,@id_priority
			,@id_tenant
			,@id_status;

		INSERT INTO _tb_tasks_histo(
			id_task
			,created_by
			,created_on
			,header
			,[description]
			,id_priority
			,id_tenant
			,id_status
			,date_histo
			,id_user_histo
			,[action]
		)
		SELECT 
			id_task
			,created_by
			,created_on
			,header
			,[description]
			,id_priority
			,id_tenant
			,id_status
			,created_on
			,created_by
			,'ins'
		FROM 
			_tb_tasks 
		WHERE 
			id_tenant = @id_tenant 
			AND id_task = @@IDENTITY
END;
GO
CREATE PROCEDURE dbo._sp_manager_statistics (
	@id_user INT
)
AS
/*
	Procedure created to allow managers to see their's underlings amount of tasks, their statuses per month
	Change log:
		(1) 2024-08-14 - Mateusz Paluch - Creation
*/
BEGIN
	DECLARE @id_tenant INT = (SELECT TOP 1 id_tenant FROM _tb_users WHERE id_user = @id_user)

	IF (SELECT is_manager FROM _tb_users WHERE id_user = @id_user) = 0
	BEGIN
		PRINT 'Ta funkcja dostêpna jest tylko dla mened¿erów'
		RETURN
	END;
		;WITH cte_users_under_managers AS
		(
			SELECT 
				id_user
			FROM
				_tb_users_managers
			WHERE 
				id_manager = @id_user
		), cte_users_tasks AS
		(
			SELECT 
				tt.id_task
			FROM 
				_tb_tasks tt
			WHERE EXISTS (SELECT 1 FROM cte_users_under_managers cte WHERE cte.id_user = tt.created_by)
		
		), cte_year_month_task AS
		(
		SELECT 
			YEAR(created_on) AS [year]
			,MONTH(created_on) AS [month]
			,id_status
			,tt.id_task
			,tt.created_by
		FROM 
			_tb_tasks tt
		JOIN 
			cte_users_tasks cta
				ON tt.id_tenant = @id_tenant
				AND cta.id_task = tt.id_task

		), final AS (
		SELECT 
			--[year]
			[month]
			,[created_by]
			,COUNT(id_task) AS num
			,id_status
		FROM 
			cte_year_month_task
		GROUP BY 
			[month]
			, created_by
			, id_status
		)
		SELECT 
			FORMAT(CAST(CONCAT(CASE 
							WHEN LEN([month]) = 1 THEN CONCAT('0', [month])
							ELSE [month]
							END
								,'-01-2020') as DATE), 'MMMM', 'PL') AS Miesiac
			,CONCAT(tu.first_name, ' ', tu.last_name) AS Podwladny
			,num as liczba_zadan
			,ts.[name] AS [status]
		FROM 
			final f
		JOIN
			_tb_status ts
				ON ts.id_status = f.id_status
		JOIN 
			_tb_users tu
				ON tu.id_user = f.created_by
		ORDER BY f.created_by ASC, [month] ASC, f.id_status DESC
END;
GO
