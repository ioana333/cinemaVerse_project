-- PROIECT ABD - CinemaVerse
-- 03 - Vederi (views). Ruleaza dupa 02_seed_data.sql.

USE CinemaVerse;
SET QUOTED_IDENTIFIER ON;
GO

-- V1. Programul viitor: proiectii cu film, cinema, sala si locuri libere
CREATE OR ALTER VIEW vw_UpcomingScreenings AS
SELECT s.screening_id, m.title, m.age_rating, m.duration_min,
       c.name AS cinema, c.city, h.name AS hall, h.hall_type,
       s.start_time, s.price, s.audio_lang, s.subtitles,
       h.capacity,
       h.capacity - COUNT(t.ticket_id) AS free_seats
FROM Screenings s
JOIN Movies  m ON m.movie_id  = s.movie_id
JOIN Halls   h ON h.hall_id   = s.hall_id
JOIN Cinemas c ON c.cinema_id = h.cinema_id
LEFT JOIN Tickets t ON t.screening_id = s.screening_id AND t.status IN ('RESERVED','PAID','USED')
WHERE s.start_time > SYSDATETIME()
GROUP BY s.screening_id, m.title, m.age_rating, m.duration_min, c.name, c.city, h.name, h.hall_type,
         s.start_time, s.price, s.audio_lang, s.subtitles, h.capacity;
GO

-- V2. Filme cu genurile lor (m-n) si nota medie data de clienti
CREATE OR ALTER VIEW vw_MovieCatalog AS
SELECT m.movie_id, m.title, m.release_date, m.duration_min, m.age_rating, m.director, m.imdb_rating,
       (SELECT STRING_AGG(g.name, ', ') WITHIN GROUP (ORDER BY g.name)
          FROM MovieGenres mg JOIN Genres g ON g.genre_id = mg.genre_id
         WHERE mg.movie_id = m.movie_id) AS genres,
       (SELECT CAST(AVG(CAST(r.rating AS DECIMAL(4,2))) AS DECIMAL(3,1)) FROM Reviews r WHERE r.movie_id = m.movie_id) AS avg_customer_rating,
       (SELECT COUNT(*) FROM Reviews r WHERE r.movie_id = m.movie_id) AS reviews_count
FROM Movies m;
GO

-- V3. Biletele clientilor (istoricul de achizitii)
CREATE OR ALTER VIEW vw_CustomerTickets AS
SELECT t.ticket_id, cu.customer_id, cu.first_name + N' ' + cu.last_name AS customer,
       m.title, c.name AS cinema, h.name AS hall, s.start_time,
       t.seat_row, t.seat_number, t.price_paid, t.status, t.channel
FROM Tickets t
JOIN Customers cu ON cu.customer_id = t.customer_id
JOIN Screenings s ON s.screening_id = t.screening_id
JOIN Movies m ON m.movie_id = s.movie_id
JOIN Halls h ON h.hall_id = s.hall_id
JOIN Cinemas c ON c.cinema_id = h.cinema_id;
GO

-- V4. Incasari pe cinematograf si film (doar bilete platite / folosite)
CREATE OR ALTER VIEW vw_Revenue AS
SELECT c.name AS cinema, m.title, COUNT(*) AS tickets_sold, SUM(t.price_paid) AS revenue
FROM Tickets t
JOIN Screenings s ON s.screening_id = t.screening_id
JOIN Movies m ON m.movie_id = s.movie_id
JOIN Halls h ON h.hall_id = s.hall_id
JOIN Cinemas c ON c.cinema_id = h.cinema_id
WHERE t.status IN ('PAID','USED')
GROUP BY c.name, m.title;
GO

-- V5. Ierarhia angajatilor (CTE recursiv pe relatia manager_id) - fara salarii
CREATE OR ALTER VIEW vw_EmployeeHierarchy AS
WITH org AS (
    SELECT employee_id, manager_id, cinema_id, first_name, last_name, position,
           0 AS level, CAST(last_name AS NVARCHAR(400)) AS path
    FROM Employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.manager_id, e.cinema_id, e.first_name, e.last_name, e.position,
           o.level + 1, CAST(o.path + N' > ' + e.last_name AS NVARCHAR(400))
    FROM Employees e JOIN org o ON e.manager_id = o.employee_id
)
SELECT o.employee_id, o.first_name, o.last_name, o.position, c.name AS cinema, o.level, o.path
FROM org o JOIN Cinemas c ON c.cinema_id = o.cinema_id;
GO

-- V6. Profilul clientului fara date sensibile (pentru personalul de la casa / analisti)
CREATE OR ALTER VIEW vw_CustomerPublic AS
SELECT customer_id, first_name, last_name, loyalty_points, registered_at FROM Customers;
GO

-- Verificare
SELECT * FROM vw_UpcomingScreenings ORDER BY start_time;
SELECT * FROM vw_MovieCatalog ORDER BY title;
SELECT * FROM vw_CustomerTickets ORDER BY customer_id, start_time;
SELECT * FROM vw_Revenue ORDER BY revenue DESC;
SELECT * FROM vw_EmployeeHierarchy ORDER BY path;
GO
