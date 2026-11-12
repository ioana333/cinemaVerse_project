-- PROIECT ABD - CinemaVerse (platforma de cinema, inspirata de Cinema City)
-- 01 - Crearea bazei de date: tabele, relatii 1-n / m-n / recursiva, constrangeri, indecsi.
-- Rulare ca sysadmin. ATENTIE: scriptul sterge si recreeaza baza de date CinemaVerse.

SET QUOTED_IDENTIFIER ON;   -- necesar pentru coloane calculate persistate / indecsi filtrati (implicit ON in SSMS)
GO
USE master;
GO
IF DB_ID('CinemaVerse') IS NOT NULL
BEGIN
    ALTER DATABASE CinemaVerse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CinemaVerse;
END
GO
CREATE DATABASE CinemaVerse;
GO
USE CinemaVerse;
SET QUOTED_IDENTIFIER ON;
GO

------------------------------------------------------------------
-- 1. Cinemas - cinematografele retelei
------------------------------------------------------------------
CREATE TABLE Cinemas (
    cinema_id  INT IDENTITY(1,1) NOT NULL,
    name       NVARCHAR(60)  NOT NULL,
    city       NVARCHAR(50)  NOT NULL,
    address    NVARCHAR(120) NOT NULL,
    phone      VARCHAR(15)   NULL,
    CONSTRAINT PK_Cinemas PRIMARY KEY CLUSTERED (cinema_id),
    CONSTRAINT UQ_Cinemas_Name UNIQUE (name),
    CONSTRAINT CK_Cinemas_Phone CHECK (phone IS NULL OR phone NOT LIKE '%[^0-9+ ]%')
);

------------------------------------------------------------------
-- 2. Halls - salile unui cinematograf (1-n cu Cinemas)
------------------------------------------------------------------
CREATE TABLE Halls (
    hall_id       INT IDENTITY(1,1) NOT NULL,
    cinema_id     INT          NOT NULL,
    name          NVARCHAR(30) NOT NULL,
    hall_type     VARCHAR(10)  NOT NULL CONSTRAINT DF_Halls_Type DEFAULT 'STANDARD',
    seat_rows     TINYINT      NOT NULL,
    seats_per_row TINYINT      NOT NULL,
    capacity      AS (CAST(seat_rows AS INT) * seats_per_row) PERSISTED,   -- coloana calculata
    CONSTRAINT PK_Halls PRIMARY KEY CLUSTERED (hall_id),
    CONSTRAINT FK_Halls_Cinemas FOREIGN KEY (cinema_id) REFERENCES Cinemas(cinema_id) ON DELETE CASCADE,
    CONSTRAINT UQ_Halls_Cinema_Name UNIQUE (cinema_id, name),
    CONSTRAINT CK_Halls_Type CHECK (hall_type IN ('STANDARD','VIP','IMAX','4DX','3D')),
    CONSTRAINT CK_Halls_Size CHECK (seat_rows BETWEEN 1 AND 30 AND seats_per_row BETWEEN 1 AND 40)
);

------------------------------------------------------------------
-- 3. Movies - filmele din catalog
------------------------------------------------------------------
CREATE TABLE Movies (
    movie_id      INT IDENTITY(1,1) NOT NULL,
    title         NVARCHAR(100) NOT NULL,
    description   NVARCHAR(500) NULL,
    duration_min  SMALLINT      NOT NULL,
    release_date  DATE          NOT NULL,
    age_rating    VARCHAR(5)    NOT NULL CONSTRAINT DF_Movies_Age DEFAULT 'AG',
    director      NVARCHAR(80)  NULL,
    imdb_rating   DECIMAL(3,1)  NULL,
    CONSTRAINT PK_Movies PRIMARY KEY CLUSTERED (movie_id),
    CONSTRAINT UQ_Movies_Title_Release UNIQUE (title, release_date),
    CONSTRAINT CK_Movies_Duration CHECK (duration_min BETWEEN 1 AND 400),
    CONSTRAINT CK_Movies_Age CHECK (age_rating IN ('AG','AP12','N15','IM18')),   -- clasificarile din Romania
    CONSTRAINT CK_Movies_Imdb CHECK (imdb_rating IS NULL OR imdb_rating BETWEEN 0 AND 10)
);

------------------------------------------------------------------
-- 4. Genres - genurile filmelor
------------------------------------------------------------------
CREATE TABLE Genres (
    genre_id INT IDENTITY(1,1) NOT NULL,
    name     NVARCHAR(40) NOT NULL,
    CONSTRAINT PK_Genres PRIMARY KEY CLUSTERED (genre_id),
    CONSTRAINT UQ_Genres_Name UNIQUE (name)
);

------------------------------------------------------------------
-- 5. MovieGenres - relatia many-to-many Movies <-> Genres
------------------------------------------------------------------
CREATE TABLE MovieGenres (
    movie_id INT NOT NULL,
    genre_id INT NOT NULL,
    CONSTRAINT PK_MovieGenres PRIMARY KEY CLUSTERED (movie_id, genre_id),
    CONSTRAINT FK_MovieGenres_Movies FOREIGN KEY (movie_id) REFERENCES Movies(movie_id) ON DELETE CASCADE,
    CONSTRAINT FK_MovieGenres_Genres FOREIGN KEY (genre_id) REFERENCES Genres(genre_id) ON DELETE CASCADE
);

------------------------------------------------------------------
-- 6. Screenings - proiectiile (film + sala + ora)
------------------------------------------------------------------
CREATE TABLE Screenings (
    screening_id INT IDENTITY(1,1) NOT NULL,
    movie_id     INT          NOT NULL,
    hall_id      INT          NOT NULL,
    start_time   DATETIME2(0) NOT NULL,
    price        DECIMAL(6,2) NOT NULL,
    audio_lang   VARCHAR(20)  NOT NULL CONSTRAINT DF_Screenings_Audio DEFAULT 'original',
    subtitles    VARCHAR(20)  NULL CONSTRAINT DF_Screenings_Sub DEFAULT 'romana',
    CONSTRAINT PK_Screenings PRIMARY KEY CLUSTERED (screening_id),
    CONSTRAINT FK_Screenings_Movies FOREIGN KEY (movie_id) REFERENCES Movies(movie_id),
    CONSTRAINT FK_Screenings_Halls  FOREIGN KEY (hall_id)  REFERENCES Halls(hall_id),
    CONSTRAINT UQ_Screenings_Hall_Start UNIQUE (hall_id, start_time),   -- o sala nu poate avea doua proiectii simultan
    CONSTRAINT CK_Screenings_Price CHECK (price > 0)
);

------------------------------------------------------------------
-- 7. Customers - clientii platformei (conturi online)
------------------------------------------------------------------
CREATE TABLE Customers (
    customer_id    INT IDENTITY(1,1) NOT NULL,
    first_name     NVARCHAR(50) NOT NULL,
    last_name      NVARCHAR(50) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    phone          VARCHAR(15)  NULL,
    birth_date     DATE         NOT NULL,
    loyalty_points INT          NOT NULL CONSTRAINT DF_Customers_Points DEFAULT 0,
    registered_at  DATETIME2(0) NOT NULL CONSTRAINT DF_Customers_Reg DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (customer_id),
    CONSTRAINT UQ_Customers_Email UNIQUE (email),
    CONSTRAINT CK_Customers_Email CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT CK_Customers_Birth CHECK (birth_date >= '1900-01-01' AND birth_date <= '2020-01-01'),
    CONSTRAINT CK_Customers_Points CHECK (loyalty_points >= 0)
);

------------------------------------------------------------------
-- 8. Tickets - biletele vandute (un rand = un loc la o proiectie)
------------------------------------------------------------------
CREATE TABLE Tickets (
    ticket_id    INT IDENTITY(1,1) NOT NULL,
    screening_id INT          NOT NULL,
    customer_id  INT          NULL,          -- NULL = bilet vandut la casa, fara cont
    seat_row     TINYINT      NOT NULL,
    seat_number  TINYINT      NOT NULL,
    price_paid   DECIMAL(6,2) NOT NULL,
    status       VARCHAR(10)  NOT NULL CONSTRAINT DF_Tickets_Status DEFAULT 'PAID',
    channel      VARCHAR(10)  NOT NULL CONSTRAINT DF_Tickets_Channel DEFAULT 'ONLINE',
    purchased_at DATETIME2(0) NOT NULL CONSTRAINT DF_Tickets_Purchased DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Tickets PRIMARY KEY CLUSTERED (ticket_id),
    CONSTRAINT FK_Tickets_Screenings FOREIGN KEY (screening_id) REFERENCES Screenings(screening_id),
    CONSTRAINT FK_Tickets_Customers  FOREIGN KEY (customer_id)  REFERENCES Customers(customer_id) ON DELETE SET NULL,
    CONSTRAINT UQ_Tickets_Seat UNIQUE (screening_id, seat_row, seat_number),   -- un loc nu se vinde de doua ori
    CONSTRAINT CK_Tickets_Status  CHECK (status IN ('RESERVED','PAID','CANCELLED','USED')),
    CONSTRAINT CK_Tickets_Channel CHECK (channel IN ('ONLINE','BOX_OFFICE','APP')),
    CONSTRAINT CK_Tickets_Price CHECK (price_paid >= 0),
    CONSTRAINT CK_Tickets_Seat CHECK (seat_row > 0 AND seat_number > 0)
);

------------------------------------------------------------------
-- 9. Reviews - recenziile clientilor (m-n Customers <-> Movies, cu atribute)
------------------------------------------------------------------
CREATE TABLE Reviews (
    customer_id INT NOT NULL,
    movie_id    INT NOT NULL,
    rating      TINYINT NOT NULL,
    comment     NVARCHAR(400) NULL,
    created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_Reviews_Created DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Reviews PRIMARY KEY CLUSTERED (customer_id, movie_id),   -- o recenzie / client / film
    CONSTRAINT FK_Reviews_Customers FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE,
    CONSTRAINT FK_Reviews_Movies    FOREIGN KEY (movie_id)    REFERENCES Movies(movie_id) ON DELETE CASCADE,
    CONSTRAINT CK_Reviews_Rating CHECK (rating BETWEEN 1 AND 10)
);

------------------------------------------------------------------
-- 10. Employees - angajatii (relatie recursiva: manager_id -> employee_id)
------------------------------------------------------------------
CREATE TABLE Employees (
    employee_id INT IDENTITY(1,1) NOT NULL,
    cinema_id   INT           NOT NULL,
    manager_id  INT           NULL,         -- NULL = varful ierarhiei (director de cinematograf)
    first_name  NVARCHAR(50)  NOT NULL,
    last_name   NVARCHAR(50)  NOT NULL,
    position    VARCHAR(20)   NOT NULL,
    salary      DECIMAL(8,2)  NOT NULL,
    hire_date   DATE          NOT NULL,
    email       VARCHAR(100)  NOT NULL,
    CONSTRAINT PK_Employees PRIMARY KEY CLUSTERED (employee_id),
    CONSTRAINT FK_Employees_Cinemas  FOREIGN KEY (cinema_id)  REFERENCES Cinemas(cinema_id),
    CONSTRAINT FK_Employees_Manager  FOREIGN KEY (manager_id) REFERENCES Employees(employee_id),
    CONSTRAINT UQ_Employees_Email UNIQUE (email),
    CONSTRAINT CK_Employees_Position CHECK (position IN ('DIRECTOR','MANAGER','CASHIER','PROJECTIONIST','CLEANER')),
    CONSTRAINT CK_Employees_Salary CHECK (salary >= 3700),     -- salariul minim brut
    CONSTRAINT CK_Employees_NotOwnManager CHECK (manager_id IS NULL OR manager_id <> employee_id)
);
GO

------------------------------------------------------------------
-- Indecsi
-- Clustered + UNIQUE sunt create implicit de PRIMARY KEY / UNIQUE de mai sus;
-- cei de mai jos sunt creati explicit (non-clustered, filtrati, unici filtrati).
------------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_Screenings_Start  ON Screenings (start_time) INCLUDE (movie_id, hall_id, price);
CREATE NONCLUSTERED INDEX IX_Screenings_Movie  ON Screenings (movie_id);
CREATE NONCLUSTERED INDEX IX_Tickets_Customer  ON Tickets (customer_id) WHERE customer_id IS NOT NULL;   -- index filtrat
CREATE NONCLUSTERED INDEX IX_Employees_Manager ON Employees (manager_id);
CREATE UNIQUE NONCLUSTERED INDEX UX_Customers_Phone ON Customers (phone) WHERE phone IS NOT NULL;       -- unic doar cand exista
GO

-- Verificare: indecsii creati
SELECT t.name AS tabel, i.name AS [index], i.type_desc, i.is_unique, i.is_primary_key
FROM sys.indexes i JOIN sys.tables t ON t.object_id = i.object_id
WHERE i.name IS NOT NULL ORDER BY t.name, i.type_desc;
GO
