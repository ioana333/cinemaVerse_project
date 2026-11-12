-- PROIECT ABD - CinemaVerse
-- 02 - Date de test. Ruleaza dupa 01_create_database.sql (identitatile pornesc de la 1).
-- Datele proiectiilor sunt relative la ziua rularii, deci raman "viitoare".

USE CinemaVerse;
SET QUOTED_IDENTIFIER ON;
GO

INSERT INTO Cinemas (name, city, address, phone) VALUES
 (N'CinemaVerse Iulius Mall Cluj', N'Cluj-Napoca', N'Str. Alexandru Vaida Voevod 53B', '0264123456'),
 (N'CinemaVerse Afi Cotroceni',    N'Bucuresti',   N'Bd. Vasile Milea 4',            '0212345678'),
 (N'CinemaVerse Shopping City',    N'Timisoara',   N'Calea Dumbravitei 1',           '0256987654'),
 (N'CinemaVerse Palas',            N'Iasi',        N'Str. Palas 7A',                 NULL);

INSERT INTO Halls (cinema_id, name, hall_type, seat_rows, seats_per_row) VALUES
 (1, N'Sala 1',    'STANDARD', 10, 14),
 (1, N'Sala IMAX', 'IMAX',     15, 20),
 (1, N'Sala VIP',  'VIP',       5,  8),
 (2, N'Sala 1',    'STANDARD', 12, 16),
 (2, N'Sala 4DX',  '4DX',       8, 10),
 (3, N'Sala 1',    'STANDARD', 10, 12),
 (3, N'Sala 3D',   '3D',       10, 14),
 (4, N'Sala 1',    'STANDARD',  9, 12);

INSERT INTO Genres (name) VALUES
 (N'Actiune'), (N'Comedie'), (N'Drama'), (N'SF'), (N'Animatie'), (N'Thriller'), (N'Romantic'), (N'Aventura');

INSERT INTO Movies (title, description, duration_min, release_date, age_rating, director, imdb_rating) VALUES
 (N'Dune: Part Two',  N'Paul Atreides se uneste cu Chani si fremenii intr-un razboi de razbunare.', 166, '2024-03-01', 'AP12', N'Denis Villeneuve', 8.5),
 (N'Oppenheimer',     N'Povestea creatorului bombei atomice.',                                      180, '2023-07-21', 'N15',  N'Christopher Nolan', 8.3),
 (N'Inside Out 2',    N'Riley intra in adolescenta si apar emotii noi.',                             96, '2024-06-14', 'AG',   N'Kelsey Mann',       7.6),
 (N'Interstellar',    N'O echipa de exploratori calatoreste printr-o gaura de vierme.',             169, '2014-11-07', 'AP12', N'Christopher Nolan', 8.7),
 (N'Barbie',          N'Barbie si Ken descopera lumea reala.',                                      114, '2023-07-21', 'AP12', N'Greta Gerwig',      6.8),
 (N'John Wick: Chapter 4', N'John Wick se infrunta cu Inalta Masa.',                                169, '2023-03-24', 'N15',  N'Chad Stahelski',    7.7),
 (N'The Batman',      N'Batman investigheaza o serie de crime din Gotham.',                         176, '2022-03-04', 'N15',  N'Matt Reeves',       7.8),
 (N'Spider-Man: Across the Spider-Verse', N'Miles Morales calatoreste prin multivers.',             140, '2023-06-02', 'AG',   N'Joaquim Dos Santos',8.6),
 (N'La La Land',      N'Un pianist si o actrita isi urmaresc visurile in Los Angeles.',             128, '2016-12-09', 'AG',   N'Damien Chazelle',   8.0),
 (N'Parasite',        N'O familie saraca se infiltreaza intr-o familie bogata.',                    132, '2019-05-30', 'N15',  N'Bong Joon-ho',      8.5);

INSERT INTO MovieGenres (movie_id, genre_id) VALUES
 (1,4),(1,8),(1,1),
 (2,3),
 (3,5),(3,2),
 (4,4),(4,3),(4,8),
 (5,2),(5,8),
 (6,1),(6,6),
 (7,1),(7,6),(7,3),
 (8,5),(8,1),(8,8),
 (9,7),(9,3),(9,2),
 (10,6),(10,3);

-- Proiectii: peste 1..3 zile, ora 12-21. Ora = miezul noptii zilei + N ore.
DECLARE @d1 DATETIME2(0) = CAST(CAST(DATEADD(DAY,1,SYSDATETIME()) AS DATE) AS DATETIME2(0));
DECLARE @d2 DATETIME2(0) = DATEADD(DAY,1,@d1);
DECLARE @d3 DATETIME2(0) = DATEADD(DAY,2,@d1);
INSERT INTO Screenings (movie_id, hall_id, start_time, price, audio_lang, subtitles) VALUES
 (1,  2, DATEADD(HOUR,18,@d1), 45.00, 'original', 'romana'),
 (1,  2, DATEADD(HOUR,21,@d1), 45.00, 'original', 'romana'),
 (2,  1, DATEADD(HOUR,17,@d1), 32.00, 'original', 'romana'),
 (3,  1, DATEADD(HOUR,14,@d2), 28.00, 'romana',   NULL),
 (4,  3, DATEADD(HOUR,20,@d2), 60.00, 'original', 'romana'),
 (5,  4, DATEADD(HOUR,16,@d1), 30.00, 'original', 'romana'),
 (6,  4, DATEADD(HOUR,21,@d1), 30.00, 'original', 'romana'),
 (7,  5, DATEADD(HOUR,19,@d3), 55.00, 'original', 'romana'),
 (8,  6, DATEADD(HOUR,15,@d2), 29.00, 'romana',   NULL),
 (9,  7, DATEADD(HOUR,19,@d2), 35.00, 'original', 'romana'),
 (10, 8, DATEADD(HOUR,20,@d1), 27.00, 'original', 'romana'),
 (3,  8, DATEADD(HOUR,12,@d3), 25.00, 'romana',   NULL);

INSERT INTO Customers (first_name, last_name, email, phone, birth_date, loyalty_points) VALUES
 (N'Andrei', N'Popescu',    'andrei.popescu@mail.ro',  '0721000001', '1998-04-12', 120),
 (N'Maria',  N'Ionescu',    'maria.ionescu@mail.ro',   '0721000002', '2001-09-30',  45),
 (N'Elena',  N'Dumitru',    'elena.dumitru@mail.ro',   '0721000003', '1995-01-22', 310),
 (N'Mihai',  N'Georgescu',  'mihai.georgescu@mail.ro', NULL,         '1989-11-05',   0),
 (N'Ioana',  N'Stan',       'ioana.stan@mail.ro',      '0721000005', '2003-06-17',  80),
 (N'Radu',   N'Marin',      'radu.marin@mail.ro',      '0721000006', '1992-02-28',  15),
 (N'Ana',    N'Toma',       'ana.toma@mail.ro',        '0721000007', '2000-12-01', 200),
 (N'Vlad',   N'Constantin', 'vlad.constantin@mail.ro', NULL,         '1997-08-09',   5);

INSERT INTO Tickets (screening_id, customer_id, seat_row, seat_number, price_paid, status, channel) VALUES
 (1,  1,    5, 10, 45.00, 'PAID',      'ONLINE'),
 (1,  1,    5, 11, 45.00, 'PAID',      'ONLINE'),
 (1,  3,    8,  4, 45.00, 'PAID',      'APP'),
 (2,  2,    7,  7, 45.00, 'PAID',      'ONLINE'),
 (3,  3,    4,  5, 32.00, 'PAID',      'ONLINE'),
 (3,  5,    4,  6, 32.00, 'RESERVED',  'APP'),
 (4,  6,    2,  3, 28.00, 'PAID',      'ONLINE'),
 (4,  NULL, 2,  4, 28.00, 'PAID',      'BOX_OFFICE'),
 (5,  7,    3,  3, 60.00, 'PAID',      'ONLINE'),
 (5,  7,    3,  4, 60.00, 'PAID',      'ONLINE'),
 (6,  4,    6,  8, 30.00, 'PAID',      'ONLINE'),
 (7,  8,    9,  1, 30.00, 'CANCELLED', 'ONLINE'),
 (8,  1,    2,  2, 55.00, 'PAID',      'ONLINE'),
 (9,  2,    5,  5, 29.00, 'PAID',      'APP'),
 (10, 3,    6,  6, 35.00, 'PAID',      'ONLINE'),
 (11, NULL, 1,  1, 27.00, 'PAID',      'BOX_OFFICE'),
 (11, 5,    1,  2, 27.00, 'PAID',      'ONLINE'),
 (12, 6,    4,  4, 25.00, 'PAID',      'ONLINE');

INSERT INTO Reviews (customer_id, movie_id, rating, comment) VALUES
 (1, 1,  10, N'Spectaculos, cel mai bun film SF al anului.'),
 (1, 2,   9, N'Interpretari excelente.'),
 (2, 3,   8, N'Amuzant si emotionant.'),
 (3, 4,  10, N'Un clasic.'),
 (3, 9,   9, N'Muzica superba.'),
 (5, 5,   6, N'Ok, dar ma asteptam la mai mult.'),
 (6, 6,   8, N'Actiune non-stop.'),
 (7, 8,   9, N'Animatie impresionanta.'),
 (7, 1,   9, NULL),
 (4, 10, 10, N'Genial.');

-- Angajati: director -> manager -> casier / operator (ierarhie pe 3 niveluri, relatie recursiva)
INSERT INTO Employees (cinema_id, manager_id, first_name, last_name, position, salary, hire_date, email) VALUES
 (1, NULL, N'Cristina', N'Pop',        'DIRECTOR',      12000, '2018-03-01', 'cristina.pop@cinemaverse.ro'),
 (1, 1,    N'Bogdan',   N'Muresan',    'MANAGER',        8000, '2020-05-15', 'bogdan.muresan@cinemaverse.ro'),
 (1, 2,    N'Larisa',   N'Rus',        'CASHIER',        4200, '2022-09-01', 'larisa.rus@cinemaverse.ro'),
 (1, 2,    N'Teodor',   N'Barbu',      'PROJECTIONIST',  4800, '2021-02-10', 'teodor.barbu@cinemaverse.ro'),
 (2, NULL, N'Sorin',    N'Draghici',   'DIRECTOR',      11500, '2017-06-01', 'sorin.draghici@cinemaverse.ro'),
 (2, 5,    N'Alina',    N'Neagu',      'MANAGER',        7800, '2019-10-01', 'alina.neagu@cinemaverse.ro'),
 (2, 6,    N'Denis',    N'Lungu',      'CASHIER',        4100, '2023-01-16', 'denis.lungu@cinemaverse.ro'),
 (3, NULL, N'Paula',    N'Vasilescu',  'DIRECTOR',      11000, '2019-04-01', 'paula.vasilescu@cinemaverse.ro');
GO

SELECT 'Cinemas' AS tabel, COUNT(*) AS randuri FROM Cinemas UNION ALL SELECT 'Halls', COUNT(*) FROM Halls
UNION ALL SELECT 'Movies', COUNT(*) FROM Movies UNION ALL SELECT 'Genres', COUNT(*) FROM Genres
UNION ALL SELECT 'MovieGenres', COUNT(*) FROM MovieGenres UNION ALL SELECT 'Screenings', COUNT(*) FROM Screenings
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers UNION ALL SELECT 'Tickets', COUNT(*) FROM Tickets
UNION ALL SELECT 'Reviews', COUNT(*) FROM Reviews UNION ALL SELECT 'Employees', COUNT(*) FROM Employees;
GO
