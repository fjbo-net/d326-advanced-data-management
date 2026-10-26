-- © 2026 FJBO
--
-- Creates the user-defined functions that transform the fields of the
-- detailed table of the business report (see 'Field Transformation' in
-- `README.md`):
--
--     fn_rental_status   rental.return_date               -> rental_status
--     fn_customer_name   customer.first_name + last_name  -> customer_name
--
-- Safe to run more than once: `CREATE OR REPLACE FUNCTION` replaces the
-- existing definition instead of failing.
--
-- Usage:
--     psql -U postgres -d dvdrental -f create-transform-function.sql


-- ---------------------------------------------------------------------
-- fn_rental_status
--
-- Turns the nullable `rental.return_date` into a label a nontechnical
-- reader understands:
--
--     NULL (copy not back yet)  -> 'Outstanding'
--     any timestamp             -> 'Returned'
--
-- Intentionally NOT declared `STRICT`: `NULL` is the input that carries
-- the meaning here, and a strict function would return `NULL` for it
-- instead of 'Outstanding'.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_rental_status(
    return_date timestamp without time zone
)

RETURNS character varying(20)

LANGUAGE sql
IMMUTABLE
PARALLEL SAFE

AS $$
    SELECT
        CASE
            WHEN return_date IS NULL
                THEN 'Outstanding'
            ELSE 'Returned'
        END;
$$;


-- ---------------------------------------------------------------------
-- fn_customer_name
--
-- Combines a first and a last name into one readable full name and
-- normalizes the capitalization:
--
--     ('MARY', 'SMITH')   -> 'Mary Smith'
--     ('  mary ', NULL)   -> 'Mary'
--     (NULL, 'SMITH')     -> 'Smith'
--     ('', NULL)          -> NULL
--
-- Edge cases:
--     * Surrounding whitespace is trimmed from each part.
--     * A part that is NULL or blank is left out, so the result never
--       has a dangling separator.
--     * When both parts are NULL or blank the result is NULL, rather
--       than an empty string.
--     * `INITCAP` lowercases the rest of every word, so 'MCDONALD'
--       becomes 'Mcdonald'. Acceptable for the DVD Rental data.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_customer_name(
    first_name character varying,
    last_name character varying
)

RETURNS character varying(91)

LANGUAGE sql
IMMUTABLE
PARALLEL SAFE

AS $$
    SELECT
        NULLIF(
            INITCAP(
                CONCAT_WS(
                    ' ',
                    NULLIF(BTRIM(first_name), ''),
                    NULLIF(BTRIM(last_name), '')
                )
            ),
            ''
        );
$$;
