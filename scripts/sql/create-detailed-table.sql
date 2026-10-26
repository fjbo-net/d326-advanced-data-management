-- © 2026 FJBO
--
-- Creates the detailed table of the business report (see 'Detailed
-- Table' in `README.md`): one row per rental event.
--
-- The fields, data types and nullability match the documentation:
--
--     * `return_date` is the only field that allows `NULL`.
--     * `rental_status` and `customer_name` hold the output of the
--       transformation functions `fn_rental_status` and
--       `fn_customer_name` (see `create-transform-function.sql`).
--     * No foreign keys point to the source tables, since the report
--       table is a denormalized snapshot of them.
--
-- The table is created empty. Its contents are refreshed by the stored
-- procedure of the report.
--
-- Safe to run more than once: the table is dropped and recreated inside
-- a transaction, so running it again rebuilds the definition instead of
-- failing. Any rows it held are lost.
--
-- Usage:
--     psql -U postgres -d dvdrental -f create-detailed-table.sql


BEGIN;

DROP TABLE IF EXISTS report_detailed;

CREATE TABLE report_detailed (
    rental_id       integer                         NOT NULL,
    rental_date     timestamp without time zone     NOT NULL,
    return_date     timestamp without time zone,
    rental_status   character varying(20)           NOT NULL,
    city            character varying(50)           NOT NULL,
    category_name   character varying(25)           NOT NULL,
    film_title      character varying(255)          NOT NULL,
    customer_id     smallint                        NOT NULL,
    customer_name   character varying(91)           NOT NULL,
    store_id        smallint                        NOT NULL,

    CONSTRAINT pk_report_detailed
        PRIMARY KEY (rental_id),

    CONSTRAINT ck_report_detailed_rental_status
        CHECK (rental_status IN ('Returned', 'Outstanding'))
);


COMMENT ON TABLE report_detailed IS
    'Detailed section of the rental report: one row per rental event.';

COMMENT ON COLUMN report_detailed.rental_id IS
    'Unique identifier of the rental event; audit key back to `rental`.';

COMMENT ON COLUMN report_detailed.rental_date IS
    'Moment the rental occurred; used to filter or trend by period.';

COMMENT ON COLUMN report_detailed.return_date IS
    'Moment the copy was returned; NULL while it is still out.';

COMMENT ON COLUMN report_detailed.rental_status IS
    'Completion state of the rental (Returned or Outstanding), from `fn_rental_status`.';

COMMENT ON COLUMN report_detailed.city IS
    'City of the customer who made the rental; the geographic dimension of the report.';

COMMENT ON COLUMN report_detailed.category_name IS
    'Film category of the rental; the value counted and ranked per city.';

COMMENT ON COLUMN report_detailed.film_title IS
    'Title of the rented film; shows which titles drive a category.';

COMMENT ON COLUMN report_detailed.customer_id IS
    'Identifier of the customer behind the rental.';

COMMENT ON COLUMN report_detailed.customer_name IS
    'Full name of the customer as one readable value, from `fn_customer_name`.';

COMMENT ON COLUMN report_detailed.store_id IS
    'Branch that supplied the rented copy.';

COMMIT;
