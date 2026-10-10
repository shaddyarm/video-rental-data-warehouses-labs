-- Первичная загрузка из учебной 3НФ модели.
-- Все таблицы получили одинаковую дату загрузки для воспроизводимости.
BEGIN;
CREATE TEMP TABLE load_context AS
SELECT TIMESTAMPTZ '2026-10-10 00:00:00+05' AS load_dts,
       'oltp.video_rental'::text AS record_source;

INSERT INTO vault.hub_customer
SELECT md5('customer|' || c.card_number), c.card_number, x.load_dts, x.record_source
FROM oltp.customer c CROSS JOIN load_context x;
INSERT INTO vault.hub_category
SELECT md5('category|' || c.name), c.name, x.load_dts, x.record_source
FROM oltp.category c CROSS JOIN load_context x;
INSERT INTO vault.hub_film
SELECT md5('film|' || f.catalog_code), f.catalog_code, x.load_dts, x.record_source
FROM oltp.film f CROSS JOIN load_context x;
INSERT INTO vault.hub_copy
SELECT md5('copy|' || c.barcode), c.barcode, x.load_dts, x.record_source
FROM oltp.copy c CROSS JOIN load_context x;
INSERT INTO vault.hub_rental
SELECT md5('rental|' || r.rental_number), r.rental_number, x.load_dts, x.record_source
FROM oltp.rental r CROSS JOIN load_context x;
INSERT INTO vault.hub_payment
SELECT md5('payment|' || p.receipt_number), p.receipt_number, x.load_dts, x.record_source
FROM oltp.payment p CROSS JOIN load_context x;

INSERT INTO vault.lnk_film_category
SELECT md5('film_category|' || f.catalog_code || '|' || c.name),
       md5('film|' || f.catalog_code), md5('category|' || c.name),
       x.load_dts, x.record_source
FROM oltp.film f JOIN oltp.category c USING(category_id)
CROSS JOIN load_context x;
INSERT INTO vault.lnk_copy_film
SELECT md5('copy_film|' || c.barcode || '|' || f.catalog_code),
       md5('copy|' || c.barcode), md5('film|' || f.catalog_code),
       x.load_dts, x.record_source
FROM oltp.copy c JOIN oltp.film f USING(film_id)
CROSS JOIN load_context x;
INSERT INTO vault.lnk_rental_assignment
SELECT md5('rental_assignment|' || r.rental_number || '|' || c.card_number || '|' || cp.barcode),
       md5('rental|' || r.rental_number),
       md5('customer|' || c.card_number), md5('copy|' || cp.barcode),
       x.load_dts, x.record_source
FROM oltp.rental r JOIN oltp.customer c USING(customer_id)
JOIN oltp.copy cp USING(copy_id) CROSS JOIN load_context x;
INSERT INTO vault.lnk_payment_rental
SELECT md5('payment_rental|' || p.receipt_number || '|' || r.rental_number),
       md5('payment|' || p.receipt_number), md5('rental|' || r.rental_number),
       x.load_dts, x.record_source
FROM oltp.payment p JOIN oltp.rental r USING(rental_id)
CROSS JOIN load_context x;

INSERT INTO vault.sat_customer_details
SELECT md5('customer|' || c.card_number), x.load_dts,
       md5(concat_ws('|', c.full_name, c.phone, c.registered_at)),
       c.full_name, c.phone, c.registered_at, x.record_source
FROM oltp.customer c CROSS JOIN load_context x;
INSERT INTO vault.sat_film_details
SELECT md5('film|' || f.catalog_code), x.load_dts,
       md5(concat_ws('|', f.title, f.release_year, f.duration_min, f.daily_rate)),
       f.title, f.release_year, f.duration_min, f.daily_rate, x.record_source
FROM oltp.film f CROSS JOIN load_context x;
INSERT INTO vault.sat_copy_details
SELECT md5('copy|' || c.barcode), x.load_dts,
       md5(c.acquired_at::text), c.acquired_at, x.record_source
FROM oltp.copy c CROSS JOIN load_context x;
INSERT INTO vault.sat_rental_terms
SELECT md5('rental|' || r.rental_number), x.load_dts,
       md5(concat_ws('|', r.rented_at, r.due_at, r.returned_at)),
       r.rented_at, r.due_at, r.returned_at, x.record_source
FROM oltp.rental r CROSS JOIN load_context x;
INSERT INTO vault.sat_payment_details
SELECT md5('payment|' || p.receipt_number), x.load_dts,
       md5(concat_ws('|', p.amount, p.paid_at, p.method)),
       p.amount, p.paid_at, p.method, x.record_source
FROM oltp.payment p CROSS JOIN load_context x;
COMMIT;
