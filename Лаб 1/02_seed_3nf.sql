-- Детерминированные учебные данные: 4 жанра, 12 фильмов, 30 копий,
-- 20 клиентов, 100 выдач и 70 платежей.
INSERT INTO oltp.category(name) VALUES
    ('Драма'), ('Комедия'), ('Фантастика'), ('Документальное кино');

INSERT INTO oltp.film(catalog_code, title, release_year, duration_min, category_id, daily_rate)
SELECT 'FILM-' || lpad(n::text, 3, '0'),
       'Фильм ' || lpad(n::text, 3, '0'),
       2005 + n, 80 + n * 3, 1 + ((n - 1) % 4),
       (90 + n * 10)::numeric(8,2)
FROM generate_series(1, 12) AS n;

INSERT INTO oltp.copy(barcode, film_id, acquired_at)
SELECT 'COPY-' || lpad(n::text, 3, '0'),
       1 + ((n - 1) % 12), DATE '2024-01-01' + n
FROM generate_series(1, 30) AS n;

INSERT INTO oltp.customer(card_number, full_name, phone, registered_at)
SELECT 'CARD-' || lpad(n::text, 3, '0'),
       'Клиент ' || lpad(n::text, 3, '0'),
       '+7-900-' || lpad(n::text, 7, '0'), DATE '2024-02-01' + n
FROM generate_series(1, 20) AS n;

INSERT INTO oltp.rental(rental_number, customer_id, copy_id, rented_at, due_at, returned_at)
SELECT 'RENT-' || lpad(n::text, 4, '0'),
       1 + ((n - 1) % 20), 1 + ((n - 1) % 30),
       TIMESTAMPTZ '2025-01-01 12:00:00+05' + n * INTERVAL '1 day',
       TIMESTAMPTZ '2025-01-06 12:00:00+05' + n * INTERVAL '1 day',
       CASE WHEN n <= 70
            THEN TIMESTAMPTZ '2025-01-05 12:00:00+05' + n * INTERVAL '1 day'
            ELSE NULL END
FROM generate_series(1, 100) AS n;

INSERT INTO oltp.payment(receipt_number, rental_id, amount, paid_at, method)
SELECT 'PAY-' || lpad(n::text, 4, '0'), n,
       f.daily_rate * 4,
       TIMESTAMPTZ '2025-01-05 15:00:00+05' + n * INTERVAL '1 day',
       CASE WHEN n % 2 = 0 THEN 'card' ELSE 'cash' END
FROM generate_series(1, 70) AS n
JOIN oltp.rental r ON r.rental_id = n
JOIN oltp.copy cp ON cp.copy_id = r.copy_id
JOIN oltp.film f ON f.film_id = cp.film_id;
