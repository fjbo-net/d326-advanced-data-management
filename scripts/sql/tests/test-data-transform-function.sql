-- © 2026 FJBO
--
-- Tests the user-defined functions created by
-- `create-transform-function.sql`:
--
--     fn_rental_status   rental.return_date               -> rental_status
--     fn_customer_name   customer.first_name + last_name  -> customer_name
--
-- The script is read-only. It has four parts:
--
--     1. Unit tests      Each case calls a function with a literal input
--                        and compares the output with the expected value.
--     2. Data tests      Run the functions against the `rental` and
--                        `customer` tables and check every row.
--     3. Detailed table  Calls the functions from the `SELECT` list, as
--                        the report does, and shows a sample.
--     4. Performance     `EXPLAIN ANALYZE` of the functions over the
--                        whole `rental` table.
--
-- Every check reports `PASS` or `FAIL` in the `result` column, so a
-- failure is visible without comparing values by eye.
--
-- Prerequisite: `create-transform-function.sql` has been run (see
-- `scripts\setup-db.bat`).
--
-- Usage:
--     psql -U postgres -d dvdrental -f test-data-transform-function.sql


-- ---------------------------------------------------------------------
-- 1. Unit tests
--
-- `IS NOT DISTINCT FROM` is used instead of `=` so that a case whose
-- expected value is `NULL` can pass: `NULL = NULL` is not true.
-- ---------------------------------------------------------------------

-- fn_rental_status: a NULL return date means the copy is still out.
SELECT
    'fn_rental_status' AS function_name,
    t.test_case,
    t.expected,
    fn_rental_status(t.return_date) AS actual,
    CASE
        WHEN fn_rental_status(t.return_date) IS NOT DISTINCT FROM t.expected
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM (
    VALUES
        ('NULL return date',        NULL::timestamp,                       'Outstanding'),
        ('Typical return date',     '2005-05-26 22:04:30'::timestamp,      'Returned'),
        ('Midnight return date',    '2005-06-01 00:00:00'::timestamp,      'Returned'),
        ('Earliest possible date',  '1900-01-01 00:00:00'::timestamp,      'Returned'),
        ('Future return date',      '2999-12-31 23:59:59'::timestamp,      'Returned'),
        ('Epoch return date',       '1970-01-01 00:00:00'::timestamp,      'Returned')
) AS t (test_case, return_date, expected);


-- fn_customer_name: combines, trims and normalizes the capitalization.
SELECT
    'fn_customer_name' AS function_name,
    t.test_case,
    t.expected,
    fn_customer_name(t.first_name, t.last_name) AS actual,
    CASE
        WHEN fn_customer_name(t.first_name, t.last_name) IS NOT DISTINCT FROM t.expected
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM (
    VALUES
        -- Valid data
        ('Uppercase name',                  'MARY',      'SMITH',     'Mary Smith'),
        ('Lowercase name',                  'mary',      'smith',     'Mary Smith'),
        ('Mixed case name',                 'mArY',      'sMiTh',     'Mary Smith'),
        ('Already formatted name',          'Mary',      'Smith',     'Mary Smith'),

        -- Whitespace
        ('Leading and trailing spaces',     '  mary ',   ' smith  ',  'Mary Smith'),

        -- Missing parts
        ('NULL last name',                  '  mary ',   NULL,        'Mary'),
        ('NULL first name',                 NULL,        'SMITH',     'Smith'),
        ('Blank last name',                 'MARY',      '',          'Mary'),
        ('Blank first name',                '',          'SMITH',     'Smith'),
        ('Whitespace-only last name',       'MARY',      '    ',      'Mary'),
        ('Whitespace-only first name',      '    ',      'SMITH',     'Smith'),

        -- No name at all
        ('Both NULL',                       NULL,        NULL,        NULL),
        ('Both blank',                      '',          '',          NULL),
        ('Both whitespace-only',            '   ',       '   ',       NULL),
        ('Blank and NULL',                  '',          NULL,        NULL),

        -- Punctuation and multi-word names
        ('Hyphenated last name',            'ANNE',      'SMITH-JONES', 'Anne Smith-Jones'),
        ('Apostrophe in last name',         'PATRICK',   'O''BRIEN',  'Patrick O''Brien'),
        ('Multi-word first name',           'MARY ANN',  'SMITH',     'Mary Ann Smith'),
        ('Multi-word last name',            'MARIA',     'DE LA CRUZ', 'Maria De La Cruz'),

        -- Known limitation: INITCAP lowercases the rest of every word.
        ('Internal capitals are lowercased', 'RONALD',   'MCDONALD',  'Ronald Mcdonald'),

        -- Non-ASCII letters
        ('Accented characters',             'JOSÉ',      'GARCÍA',    'José García')
) AS t (test_case, first_name, last_name, expected);


-- ---------------------------------------------------------------------
-- 2. Data tests
--
-- Each query returns one row. `rows_checked` is how many rows were
-- inspected and `failures` how many broke the rule, so `PASS` also
-- proves the table was not empty.
-- ---------------------------------------------------------------------

-- fn_rental_status returns 'Outstanding' for exactly the rentals with
-- no return date and 'Returned' for all others, and nothing else.
SELECT
    'fn_rental_status matches rental.return_date' AS test_case,
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE fn_rental_status(r.return_date) IS DISTINCT FROM
            CASE WHEN r.return_date IS NULL THEN 'Outstanding' ELSE 'Returned' END
    ) AS failures,
    CASE
        WHEN COUNT(*) > 0
            AND COUNT(*) FILTER (
                WHERE fn_rental_status(r.return_date) IS DISTINCT FROM
                    CASE WHEN r.return_date IS NULL THEN 'Outstanding' ELSE 'Returned' END
            ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM rental AS r;


-- The function never returns NULL or an unexpected label.
SELECT
    'fn_rental_status returns only known labels' AS test_case,
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE fn_rental_status(r.return_date) IS NULL
            OR fn_rental_status(r.return_date) NOT IN ('Outstanding', 'Returned')
    ) AS failures,
    CASE
        WHEN COUNT(*) > 0
            AND COUNT(*) FILTER (
                WHERE fn_rental_status(r.return_date) IS NULL
                    OR fn_rental_status(r.return_date) NOT IN ('Outstanding', 'Returned')
            ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM rental AS r;


-- Both labels occur in the dataset, so both branches of the function are
-- exercised by real data.
SELECT
    'fn_rental_status covers both labels in the data' AS test_case,
    COUNT(*) FILTER (WHERE rental_status = 'Outstanding') AS outstanding_rows,
    COUNT(*) FILTER (WHERE rental_status = 'Returned') AS returned_rows,
    CASE
        WHEN COUNT(*) FILTER (WHERE rental_status = 'Outstanding') > 0
            AND COUNT(*) FILTER (WHERE rental_status = 'Returned') > 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM (
    SELECT fn_rental_status(r.return_date) AS rental_status
    FROM rental AS r
) AS s;


-- Every customer gets a non-empty name with no leading, trailing or
-- doubled spaces.
SELECT
    'fn_customer_name produces clean names' AS test_case,
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE fn_customer_name(c.first_name, c.last_name) IS NULL
            OR fn_customer_name(c.first_name, c.last_name) <> BTRIM(fn_customer_name(c.first_name, c.last_name))
            OR fn_customer_name(c.first_name, c.last_name) LIKE '%  %'
    ) AS failures,
    CASE
        WHEN COUNT(*) > 0
            AND COUNT(*) FILTER (
                WHERE fn_customer_name(c.first_name, c.last_name) IS NULL
                    OR fn_customer_name(c.first_name, c.last_name) <> BTRIM(fn_customer_name(c.first_name, c.last_name))
                    OR fn_customer_name(c.first_name, c.last_name) LIKE '%  %'
            ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM customer AS c;


-- The name is exactly the first name, a space and the last name, ignoring
-- case. This proves no letters were lost or reordered.
SELECT
    'fn_customer_name keeps first name then last name' AS test_case,
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE LOWER(fn_customer_name(c.first_name, c.last_name))
            IS DISTINCT FROM LOWER(BTRIM(c.first_name) || ' ' || BTRIM(c.last_name))
    ) AS failures,
    CASE
        WHEN COUNT(*) > 0
            AND COUNT(*) FILTER (
                WHERE LOWER(fn_customer_name(c.first_name, c.last_name))
                    IS DISTINCT FROM LOWER(BTRIM(c.first_name) || ' ' || BTRIM(c.last_name))
            ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM customer AS c;


-- The result fits the declared return type `character varying(91)`
-- (45 + 1 + 45), which is what the report column is sized for.
SELECT
    'fn_customer_name fits the return type' AS test_case,
    MAX(LENGTH(fn_customer_name(c.first_name, c.last_name))) AS longest_name,
    CASE
        WHEN MAX(LENGTH(fn_customer_name(c.first_name, c.last_name))) <= 91
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM customer AS c;


-- ---------------------------------------------------------------------
-- 3. Detailed table
--
-- Calls the functions from the `SELECT` list, joined across tables, the
-- way the report does. The raw columns are shown next to the transformed
-- ones so the transformation can be verified by eye. Outstanding rentals
-- are listed first so both labels appear in the sample.
-- ---------------------------------------------------------------------
SELECT
    r.rental_id,
    r.rental_date,
    r.return_date,
    fn_rental_status(r.return_date) AS rental_status,
    c.first_name,
    c.last_name,
    fn_customer_name(c.first_name, c.last_name) AS customer_name

FROM rental AS r
    INNER JOIN customer AS c
        ON c.customer_id = r.customer_id

ORDER BY
    (r.return_date IS NOT NULL),
    r.rental_id

LIMIT 10;


-- The functions can be used in a `WHERE` clause, not only the `SELECT`
-- list: count the rentals still out, per the function and per the column.
SELECT
    'fn_rental_status works in a WHERE clause' AS test_case,
    COUNT(*) AS via_function,
    (SELECT COUNT(*) FROM rental WHERE return_date IS NULL) AS via_column,
    CASE
        WHEN COUNT(*) = (SELECT COUNT(*) FROM rental WHERE return_date IS NULL)
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM rental AS r
WHERE fn_rental_status(r.return_date) = 'Outstanding';


-- ---------------------------------------------------------------------
-- 4. Performance
--
-- Applies both functions to every row. The "Execution Time" line at the
-- end of each plan should be small (well under a second for the DVD
-- Rental dataset of roughly 16,000 rentals and 600 customers).
-- ---------------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    fn_rental_status(r.return_date) AS rental_status

FROM rental AS r;


EXPLAIN (ANALYZE, BUFFERS)
SELECT
    fn_customer_name(c.first_name, c.last_name) AS customer_name

FROM customer AS c;
