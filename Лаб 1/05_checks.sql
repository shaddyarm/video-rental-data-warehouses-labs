-- Контроль соответствия операционной модели и первичной загрузки Data Vault.
SELECT 'category' AS entity, (SELECT count(*) FROM oltp.category) AS oltp_count,
       (SELECT count(*) FROM vault.hub_category) AS vault_count
UNION ALL SELECT 'film', (SELECT count(*) FROM oltp.film), (SELECT count(*) FROM vault.hub_film)
UNION ALL SELECT 'copy', (SELECT count(*) FROM oltp.copy), (SELECT count(*) FROM vault.hub_copy)
UNION ALL SELECT 'customer', (SELECT count(*) FROM oltp.customer), (SELECT count(*) FROM vault.hub_customer)
UNION ALL SELECT 'rental', (SELECT count(*) FROM oltp.rental), (SELECT count(*) FROM vault.hub_rental)
UNION ALL SELECT 'payment', (SELECT count(*) FROM oltp.payment), (SELECT count(*) FROM vault.hub_payment)
ORDER BY entity;

SELECT count(*) AS assignment_links FROM vault.lnk_rental_assignment;
SELECT count(*) AS open_rentals FROM oltp.rental WHERE returned_at IS NULL;
SELECT sum(amount) AS paid_total FROM oltp.payment;

-- Проверка историзации на одном клиенте. Исходные данные не меняются:
-- добавляется только вторая версия спутника с новой датой загрузки.
INSERT INTO vault.sat_customer_details
    (customer_hk, load_dts, hashdiff, full_name, phone, registered_at, record_source)
SELECT customer_hk, TIMESTAMPTZ '2026-10-11 00:00:00+05',
       md5(concat_ws('|', full_name, '+7-900-9999999', registered_at)),
       full_name, '+7-900-9999999', registered_at, 'change_event'
FROM vault.sat_customer_details s
WHERE s.customer_hk = md5('customer|CARD-001')
  AND s.load_dts = TIMESTAMPTZ '2026-10-10 00:00:00+05'
ON CONFLICT (customer_hk, load_dts) DO NOTHING;

SELECT h.card_number, s.load_dts, s.phone
FROM vault.hub_customer h
JOIN vault.sat_customer_details s USING(customer_hk)
WHERE h.card_number = 'CARD-001'
ORDER BY s.load_dts;
