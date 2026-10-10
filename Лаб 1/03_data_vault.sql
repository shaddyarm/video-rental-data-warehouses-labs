-- Data Vault для того же процесса видеопроката.
-- HUB хранит устойчивый бизнес-ключ, LINK фиксирует отношение,
-- SAT хранит версию изменяемых атрибутов и hashdiff.
-- MD5 здесь служит детерминированным учебным суррогатным ключом,
-- а не средством защиты данных.
DROP SCHEMA IF EXISTS vault CASCADE;
CREATE SCHEMA vault;

CREATE TABLE vault.hub_customer (
    customer_hk char(32) PRIMARY KEY,
    card_number varchar(20) NOT NULL UNIQUE,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL
);
CREATE TABLE vault.hub_category (
    category_hk char(32) PRIMARY KEY,
    category_name text NOT NULL UNIQUE,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL
);
CREATE TABLE vault.hub_film (
    film_hk char(32) PRIMARY KEY,
    catalog_code varchar(20) NOT NULL UNIQUE,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL
);
CREATE TABLE vault.hub_copy (
    copy_hk char(32) PRIMARY KEY,
    barcode varchar(30) NOT NULL UNIQUE,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL
);
CREATE TABLE vault.hub_rental (
    rental_hk char(32) PRIMARY KEY,
    rental_number varchar(20) NOT NULL UNIQUE,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL
);
CREATE TABLE vault.hub_payment (
    payment_hk char(32) PRIMARY KEY,
    receipt_number varchar(20) NOT NULL UNIQUE,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL
);

CREATE TABLE vault.lnk_film_category (
    film_category_hk char(32) PRIMARY KEY,
    film_hk char(32) NOT NULL REFERENCES vault.hub_film,
    category_hk char(32) NOT NULL REFERENCES vault.hub_category,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    UNIQUE(film_hk, category_hk)
);
CREATE TABLE vault.lnk_copy_film (
    copy_film_hk char(32) PRIMARY KEY,
    copy_hk char(32) NOT NULL REFERENCES vault.hub_copy,
    film_hk char(32) NOT NULL REFERENCES vault.hub_film,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    UNIQUE(copy_hk, film_hk)
);
CREATE TABLE vault.lnk_rental_assignment (
    rental_assignment_hk char(32) PRIMARY KEY,
    rental_hk char(32) NOT NULL REFERENCES vault.hub_rental,
    customer_hk char(32) NOT NULL REFERENCES vault.hub_customer,
    copy_hk char(32) NOT NULL REFERENCES vault.hub_copy,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    UNIQUE(rental_hk, customer_hk, copy_hk)
);
CREATE TABLE vault.lnk_payment_rental (
    payment_rental_hk char(32) PRIMARY KEY,
    payment_hk char(32) NOT NULL REFERENCES vault.hub_payment,
    rental_hk char(32) NOT NULL REFERENCES vault.hub_rental,
    load_dts timestamptz NOT NULL,
    record_source text NOT NULL,
    UNIQUE(payment_hk, rental_hk)
);

CREATE TABLE vault.sat_customer_details (
    customer_hk char(32) NOT NULL REFERENCES vault.hub_customer,
    load_dts timestamptz NOT NULL,
    hashdiff char(32) NOT NULL,
    full_name text NOT NULL,
    phone varchar(30) NOT NULL,
    registered_at date NOT NULL,
    record_source text NOT NULL,
    PRIMARY KEY(customer_hk, load_dts)
);
CREATE TABLE vault.sat_film_details (
    film_hk char(32) NOT NULL REFERENCES vault.hub_film,
    load_dts timestamptz NOT NULL,
    hashdiff char(32) NOT NULL,
    title text NOT NULL,
    release_year integer NOT NULL,
    duration_min integer NOT NULL,
    daily_rate numeric(8,2) NOT NULL,
    record_source text NOT NULL,
    PRIMARY KEY(film_hk, load_dts)
);
CREATE TABLE vault.sat_copy_details (
    copy_hk char(32) NOT NULL REFERENCES vault.hub_copy,
    load_dts timestamptz NOT NULL,
    hashdiff char(32) NOT NULL,
    acquired_at date NOT NULL,
    record_source text NOT NULL,
    PRIMARY KEY(copy_hk, load_dts)
);
CREATE TABLE vault.sat_rental_terms (
    rental_hk char(32) NOT NULL REFERENCES vault.hub_rental,
    load_dts timestamptz NOT NULL,
    hashdiff char(32) NOT NULL,
    rented_at timestamptz NOT NULL,
    due_at timestamptz NOT NULL,
    returned_at timestamptz,
    record_source text NOT NULL,
    PRIMARY KEY(rental_hk, load_dts)
);
CREATE TABLE vault.sat_payment_details (
    payment_hk char(32) NOT NULL REFERENCES vault.hub_payment,
    load_dts timestamptz NOT NULL,
    hashdiff char(32) NOT NULL,
    amount numeric(10,2) NOT NULL,
    paid_at timestamptz NOT NULL,
    method varchar(10) NOT NULL,
    record_source text NOT NULL,
    PRIMARY KEY(payment_hk, load_dts)
);

COMMENT ON SCHEMA vault IS 'Историзированная модель Data Vault видеопроката';
COMMENT ON TABLE vault.lnk_rental_assignment IS 'Один факт выдачи связывает номер выдачи, клиента и физический экземпляр';
COMMENT ON TABLE vault.sat_rental_terms IS 'Новая строка создается при изменении срока или факта возврата';
