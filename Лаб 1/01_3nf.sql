-- Вариант 14: учет в видеопрокате. Операционная модель в 3НФ.
-- Повторный запуск удаляет только учебную схему oltp.
DROP SCHEMA IF EXISTS oltp CASCADE;
CREATE SCHEMA oltp;

CREATE TABLE oltp.category (
    category_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE CHECK (btrim(name) <> '')
);

CREATE TABLE oltp.film (
    film_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    catalog_code varchar(20) NOT NULL UNIQUE,
    title text NOT NULL CHECK (btrim(title) <> ''),
    release_year integer NOT NULL CHECK (release_year BETWEEN 1895 AND 2100),
    duration_min integer NOT NULL CHECK (duration_min > 0),
    category_id bigint NOT NULL REFERENCES oltp.category(category_id),
    daily_rate numeric(8,2) NOT NULL CHECK (daily_rate > 0)
);

CREATE TABLE oltp.copy (
    copy_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    barcode varchar(30) NOT NULL UNIQUE,
    film_id bigint NOT NULL REFERENCES oltp.film(film_id),
    acquired_at date NOT NULL
);

CREATE TABLE oltp.customer (
    customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    card_number varchar(20) NOT NULL UNIQUE,
    full_name text NOT NULL CHECK (btrim(full_name) <> ''),
    phone varchar(30) NOT NULL,
    registered_at date NOT NULL
);

CREATE TABLE oltp.rental (
    rental_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rental_number varchar(20) NOT NULL UNIQUE,
    customer_id bigint NOT NULL REFERENCES oltp.customer(customer_id),
    copy_id bigint NOT NULL REFERENCES oltp.copy(copy_id),
    rented_at timestamptz NOT NULL,
    due_at timestamptz NOT NULL,
    returned_at timestamptz,
    CONSTRAINT rental_due_after_start CHECK (due_at > rented_at),
    CONSTRAINT rental_return_after_start CHECK (returned_at IS NULL OR returned_at >= rented_at)
);
-- Один экземпляр не может одновременно числиться в двух открытых выдачах.
CREATE UNIQUE INDEX one_open_rental_per_copy ON oltp.rental(copy_id)
    WHERE returned_at IS NULL;
CREATE INDEX rental_customer_idx ON oltp.rental(customer_id, rented_at DESC);

CREATE TABLE oltp.payment (
    payment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_number varchar(20) NOT NULL UNIQUE,
    rental_id bigint NOT NULL REFERENCES oltp.rental(rental_id),
    amount numeric(10,2) NOT NULL CHECK (amount > 0),
    paid_at timestamptz NOT NULL,
    method varchar(10) NOT NULL CHECK (method IN ('cash', 'card'))
);
CREATE INDEX payment_rental_idx ON oltp.payment(rental_id);

COMMENT ON SCHEMA oltp IS 'Операционный учет видеопроката, вариант 14';
COMMENT ON TABLE oltp.film IS 'Название в каталоге; один фильм может иметь несколько физических экземпляров';
COMMENT ON TABLE oltp.copy IS 'Физический экземпляр с уникальным штрихкодом';
COMMENT ON TABLE oltp.rental IS 'Факт выдачи одного экземпляра одному клиенту';
COMMENT ON TABLE oltp.payment IS 'Платеж по выдаче; выдача может иметь несколько платежей';
