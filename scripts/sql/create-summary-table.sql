-- © 2026 FJBO
--
-- Creates the summary table of the business report (see 'Summary
-- Table' in `README.md`): one row per city and film category.
--
-- The fields, data types and nullability match the documentation:
--
--     * Every field is `NOT NULL`: a row exists only because at least
--       one rental produced it, so every aggregate has a value.
--     * The pair (`city`, `category_name`) is the grain and the primary
--       key.
--     * Check constraints enforce the domains of values of the data
--       dictionary.
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
--     psql -U postgres -d dvdrental -f create-summary-table.sql


BEGIN;

DROP TABLE IF EXISTS report_summary;

CREATE TABLE report_summary (
    city                    character varying(50)   NOT NULL,
    category_name           character varying(25)   NOT NULL,
    rental_count            integer                 NOT NULL,
    category_rank           integer                 NOT NULL,
    city_rental_total       integer                 NOT NULL,
    share_of_city_rentals   numeric(5,2)            NOT NULL,
    distinct_customers      integer                 NOT NULL,
    outstanding_rentals     integer                 NOT NULL,
    latest_rental_date      date                    NOT NULL,

    CONSTRAINT pk_report_summary
        PRIMARY KEY (city, category_name),

    CONSTRAINT ck_report_summary_rental_count
        CHECK (rental_count >= 1),

    CONSTRAINT ck_report_summary_category_rank
        CHECK (category_rank >= 1),

    CONSTRAINT ck_report_summary_city_rental_total
        CHECK (city_rental_total >= rental_count),

    CONSTRAINT ck_report_summary_share_of_city_rentals
        CHECK (share_of_city_rentals BETWEEN 0 AND 100),

    CONSTRAINT ck_report_summary_distinct_customers
        CHECK (distinct_customers BETWEEN 1 AND rental_count),

    CONSTRAINT ck_report_summary_outstanding_rentals
        CHECK (outstanding_rentals BETWEEN 0 AND rental_count)
);


COMMENT ON TABLE report_summary IS
    'Summary section of the rental report: one row per city and film category.';

COMMENT ON COLUMN report_summary.city IS
    'City the rentals were made in; the geographic dimension of the report.';

COMMENT ON COLUMN report_summary.category_name IS
    'Film category being counted and ranked within the city.';

COMMENT ON COLUMN report_summary.rental_count IS
    'Number of rentals of the category in the city; the measure that answers the business question.';

COMMENT ON COLUMN report_summary.category_rank IS
    'Position of the category within its city by rental count; 1 is the most rented and ties share a rank.';

COMMENT ON COLUMN report_summary.city_rental_total IS
    'Total rentals in the city across all categories; sizes the market behind the ranking.';

COMMENT ON COLUMN report_summary.share_of_city_rentals IS
    'Percentage of the city''s rentals accounted for by the category, from 0.00 to 100.00.';

COMMENT ON COLUMN report_summary.distinct_customers IS
    'Number of different customers behind the rentals; separates broad appetite from a few heavy renters.';

COMMENT ON COLUMN report_summary.outstanding_rentals IS
    'Number of the category''s rentals not yet returned; shows demand throttled by unavailable stock.';

COMMENT ON COLUMN report_summary.latest_rental_date IS
    'Date of the most recent rental of the category in the city; shows whether a lead is current.';

COMMIT;
