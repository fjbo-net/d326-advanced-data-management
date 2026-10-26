-- © 2026 FJBO
--
-- Tests the detailed table created by `create-detailed-table.sql`
-- (see 'Detailed Table' under 'Report Tables' in `README.md`):
--
--     report_detailed   one row per rental event
--
-- The script leaves the database unchanged. It has four parts:
--
--     1. Structure       Every field exists with the documented name,
--                        data type, length and nullability, and no
--                        undocumented field exists.
--     2. Constraints     The primary key and the check constraint exist
--                        and cover the documented columns.
--     3. Behaviour       Valid rows are accepted and invalid rows
--                        (duplicate `rental_id`, `NULL` in a required
--                        field, unknown `rental_status`, values longer
--                        than the field) are rejected.
--     4. Compatibility   The real data of the source tables, transformed
--                        by `fn_rental_status` and `fn_customer_name`,
--                        is inserted into the table.
--
-- Parts 3 and 4 write to the table, so everything runs inside a
-- transaction that ends with `ROLLBACK`: nothing is kept, and any rows
-- the table already held are restored. The only objects created are a
-- helper function and a helper table in the session's temporary schema,
-- which disappear with the rollback.
--
-- Every check reports `PASS` or `FAIL` in the `result` column, so a
-- failure is visible without comparing values by eye.
--
-- Prerequisite: `create-transform-function.sql` and
-- `create-detailed-table.sql` have been run (see `scripts\setup-db.bat`).
--
-- Usage:
--     psql -U postgres -d dvdrental -f test-detailed-table.sql


BEGIN;


-- ---------------------------------------------------------------------
-- 1. Structure
--
-- Each documented field is compared with `information_schema.columns`.
-- `IS NOT DISTINCT FROM` is used instead of `=` so that two `NULL`
-- lengths (a field without a length) count as equal.
-- ---------------------------------------------------------------------

SELECT
    e.field AS test_case,
    e.data_type AS expected_type,
    a.data_type AS actual_type,
    e.max_length AS expected_length,
    a.character_maximum_length AS actual_length,
    e.nullable AS expected_nullable,
    a.is_nullable AS actual_nullable,
    CASE
        WHEN a.column_name IS NOT NULL
            AND a.data_type = e.data_type
            AND a.character_maximum_length IS NOT DISTINCT FROM e.max_length
            AND a.is_nullable = e.nullable
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM (
    VALUES
        (1,  'rental_id',     'integer',                      NULL::integer, 'NO'),
        (2,  'rental_date',   'timestamp without time zone',  NULL,          'NO'),
        (3,  'return_date',   'timestamp without time zone',  NULL,          'YES'),
        (4,  'rental_status', 'character varying',            20,            'NO'),
        (5,  'city',          'character varying',            50,            'NO'),
        (6,  'category_name', 'character varying',            25,            'NO'),
        (7,  'film_title',    'character varying',            255,           'NO'),
        (8,  'customer_id',   'smallint',                     NULL,          'NO'),
        (9,  'customer_name', 'character varying',            91,            'NO'),
        (10, 'store_id',      'smallint',                     NULL,          'NO')
) AS e (position, field, data_type, max_length, nullable)
    LEFT JOIN information_schema.columns AS a
        ON a.table_schema = 'public'
        AND a.table_name = 'report_detailed'
        AND a.column_name = e.field

ORDER BY e.position;


-- The table has exactly the documented fields, no more and no fewer.
SELECT
    'Table has exactly 10 fields' AS test_case,
    COUNT(*) AS actual_fields,
    CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END AS result

FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'report_detailed';


-- `return_date` is the only field that allows NULL.
SELECT
    'Only return_date is nullable' AS test_case,
    COALESCE(STRING_AGG(column_name, ', ' ORDER BY column_name), '(none)') AS nullable_fields,
    CASE
        WHEN COALESCE(STRING_AGG(column_name, ', '), '') = 'return_date' THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM information_schema.columns
WHERE table_schema = 'public'
    AND table_name = 'report_detailed'
    AND is_nullable = 'YES';


-- Every field carries a business description (visible in `\d+`).
SELECT
    'Every field has a COMMENT' AS test_case,
    COUNT(*) AS fields_checked,
    COUNT(*) FILTER (WHERE d.description IS NULL) AS failures,
    CASE
        WHEN COUNT(*) = 10 AND COUNT(*) FILTER (WHERE d.description IS NULL) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM pg_attribute AS a
    LEFT JOIN pg_description AS d
        ON d.objoid = a.attrelid
        AND d.objsubid = a.attnum
WHERE a.attrelid = to_regclass('public.report_detailed')
    AND a.attnum > 0
    AND NOT a.attisdropped;


-- ---------------------------------------------------------------------
-- 2. Constraints
-- ---------------------------------------------------------------------

-- The primary key is on `rental_id` alone.
SELECT
    'Primary key pk_report_detailed on rental_id' AS test_case,
    k.columns AS actual_columns,
    CASE
        WHEN EXISTS (
                SELECT 1
                FROM information_schema.table_constraints AS t
                WHERE t.table_schema = 'public'
                    AND t.table_name = 'report_detailed'
                    AND t.constraint_name = 'pk_report_detailed'
                    AND t.constraint_type = 'PRIMARY KEY'
            )
            AND k.columns = 'rental_id'
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM (
    SELECT STRING_AGG(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS columns
    FROM information_schema.key_column_usage AS kcu
    WHERE kcu.table_schema = 'public'
        AND kcu.table_name = 'report_detailed'
        AND kcu.constraint_name = 'pk_report_detailed'
) AS k;


-- The check constraint exists and limits `rental_status` to the output
-- of `fn_rental_status`.
SELECT
    'Check constraint ck_report_detailed_rental_status' AS test_case,
    (
        SELECT pg_get_constraintdef(c.oid)
        FROM pg_constraint AS c
        WHERE c.conrelid = to_regclass('public.report_detailed')
            AND c.conname = 'ck_report_detailed_rental_status'
    ) AS definition,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_constraint AS c
            WHERE c.conrelid = to_regclass('public.report_detailed')
                AND c.conname = 'ck_report_detailed_rental_status'
                AND c.contype = 'c'
                AND pg_get_constraintdef(c.oid) LIKE '%rental_status%'
                AND pg_get_constraintdef(c.oid) LIKE '%Returned%'
                AND pg_get_constraintdef(c.oid) LIKE '%Outstanding%'
        )
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result;


-- No foreign keys: the table is a denormalized snapshot of the sources.
SELECT
    'No foreign keys to the source tables' AS test_case,
    COUNT(*) AS foreign_keys,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result

FROM pg_constraint
WHERE conrelid = to_regclass('public.report_detailed')
    AND contype = 'f';


-- ---------------------------------------------------------------------
-- 3. Behaviour
--
-- `try_insert` inserts one row, given as JSON, and returns `OK` or the
-- SQLSTATE of the error. The error is caught so a rejected row is
-- reported instead of aborting the script, and only that insert is
-- undone. Rows with negative `rental_id` cannot collide with real data.
--
--     23505  unique_violation
--     23502  not_null_violation
--     23514  check_violation
--     22001  string_data_right_truncation
--
-- The table is emptied first (and restored by the final `ROLLBACK`) so
-- the counts below only see the rows of this script.
-- ---------------------------------------------------------------------

CREATE FUNCTION pg_temp.try_insert(p_row jsonb)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO report_detailed
    SELECT * FROM jsonb_populate_record(NULL::report_detailed, p_row);

    RETURN 'OK';
EXCEPTION
    WHEN OTHERS THEN
        RETURN SQLSTATE;
END;
$$;

DELETE FROM report_detailed;


-- A valid row, used as the base of every case.
CREATE TEMPORARY TABLE base_row ON COMMIT DROP AS
SELECT
    jsonb_build_object(
        'rental_id',     -1,
        'rental_date',   '2005-05-24 22:53:30',
        'return_date',   '2005-05-26 22:04:30',
        'rental_status', 'Returned',
        'city',          'Lethbridge',
        'category_name', 'Action',
        'film_title',    'ACADEMY DINOSAUR',
        'customer_id',   1,
        'customer_name', 'Mary Smith',
        'store_id',      1
    ) AS r;


-- Valid rows are accepted. `LATERAL` runs each insert once, so the
-- reported `actual` is the outcome that `result` judges.
SELECT
    t.test_case,
    'OK' AS expected,
    x.actual,
    CASE WHEN x.actual = 'OK' THEN 'PASS' ELSE 'FAIL' END AS result

FROM (
    SELECT 'Valid returned rental' AS test_case, 1 AS n, r AS new_row
    FROM base_row

    UNION ALL
    SELECT 'Valid outstanding rental (NULL return_date)', 2,
        r || '{"rental_id": -2, "rental_status": "Outstanding", "return_date": null}'::jsonb
    FROM base_row

    UNION ALL
    SELECT 'Maximum length values', 3,
        r || jsonb_build_object(
            'rental_id', -3,
            'city', REPEAT('c', 50),
            'category_name', REPEAT('k', 25),
            'film_title', REPEAT('f', 255),
            'customer_name', REPEAT('n', 91)
        )
    FROM base_row

    UNION ALL
    SELECT 'Largest smallint ids', 4,
        r || '{"rental_id": -4, "customer_id": 32767, "store_id": 32767}'::jsonb
    FROM base_row
) AS t
    CROSS JOIN LATERAL (SELECT pg_temp.try_insert(t.new_row) AS actual) AS x

ORDER BY t.n;


-- Invalid rows are rejected with the expected error.
SELECT
    t.test_case,
    t.expected,
    x.actual,
    CASE WHEN x.actual = t.expected THEN 'PASS' ELSE 'FAIL' END AS result

FROM (
    SELECT 'Duplicate rental_id' AS test_case, 1 AS n, '23505' AS expected,
        r AS new_row
    FROM base_row

    UNION ALL
    SELECT 'Unknown rental_status', 2, '23514',
        r || '{"rental_id": -10, "rental_status": "Lost"}'::jsonb
    FROM base_row

    UNION ALL
    SELECT 'rental_status in lowercase', 3, '23514',
        r || '{"rental_id": -11, "rental_status": "returned"}'::jsonb
    FROM base_row

    UNION ALL
    SELECT 'Empty rental_status', 4, '23514',
        r || '{"rental_id": -12, "rental_status": ""}'::jsonb
    FROM base_row

    UNION ALL
    SELECT 'NULL rental_id', 5, '23502',
        r || '{"rental_id": null}'::jsonb
    FROM base_row

    UNION ALL
    SELECT 'NULL ' || f.field, 10 + f.position, '23502',
        r || jsonb_build_object('rental_id', -100 - f.position, f.field, NULL::text)
    FROM base_row
        CROSS JOIN (
            VALUES
                (1, 'rental_date'),
                (2, 'rental_status'),
                (3, 'city'),
                (4, 'category_name'),
                (5, 'film_title'),
                (6, 'customer_id'),
                (7, 'customer_name'),
                (8, 'store_id')
        ) AS f (position, field)

    UNION ALL
    SELECT 'city longer than 50', 30, '22001',
        r || jsonb_build_object('rental_id', -30, 'city', REPEAT('c', 51))
    FROM base_row

    UNION ALL
    SELECT 'category_name longer than 25', 31, '22001',
        r || jsonb_build_object('rental_id', -31, 'category_name', REPEAT('k', 26))
    FROM base_row

    UNION ALL
    SELECT 'film_title longer than 255', 32, '22001',
        r || jsonb_build_object('rental_id', -32, 'film_title', REPEAT('f', 256))
    FROM base_row

    UNION ALL
    SELECT 'customer_name longer than 91', 33, '22001',
        r || jsonb_build_object('rental_id', -33, 'customer_name', REPEAT('n', 92))
    FROM base_row
) AS t
    CROSS JOIN LATERAL (SELECT pg_temp.try_insert(t.new_row) AS actual) AS x

ORDER BY t.n;


-- Only the four valid rows were kept, so every rejected row left no
-- trace behind.
SELECT
    'Rejected rows were not stored' AS test_case,
    COUNT(*) AS rows_in_table,
    CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END AS result

FROM report_detailed;


-- ---------------------------------------------------------------------
-- 4. Compatibility
--
-- Inserts one row per rental through the full JOIN path of the source
-- tables, calling the transformation functions from the `SELECT` list,
-- as the report does. The insert fails (and aborts the script) if any
-- real value breaks a type, length, `NOT NULL` or constraint rule.
-- ---------------------------------------------------------------------

DELETE FROM report_detailed;

INSERT INTO report_detailed (
    rental_id,
    rental_date,
    return_date,
    rental_status,
    city,
    category_name,
    film_title,
    customer_id,
    customer_name,
    store_id
)
SELECT
    r.rental_id,
    r.rental_date,
    r.return_date,
    fn_rental_status(r.return_date),
    ci.city,
    cat.name,
    f.title,
    c.customer_id,
    fn_customer_name(c.first_name, c.last_name),
    i.store_id

FROM rental AS r
    INNER JOIN inventory AS i
        ON i.inventory_id = r.inventory_id
    INNER JOIN film AS f
        ON f.film_id = i.film_id
    INNER JOIN film_category AS fc
        ON fc.film_id = i.film_id
    INNER JOIN category AS cat
        ON cat.category_id = fc.category_id
    INNER JOIN customer AS c
        ON c.customer_id = r.customer_id
    INNER JOIN address AS a
        ON a.address_id = c.address_id
    INNER JOIN city AS ci
        ON ci.city_id = a.city_id;


-- Every rental made it into the table: none was lost by a join.
SELECT
    'One row per rental' AS test_case,
    (SELECT COUNT(*) FROM rental) AS rentals,
    COUNT(*) AS rows_inserted,
    CASE
        WHEN COUNT(*) > 0 AND COUNT(*) = (SELECT COUNT(*) FROM rental) THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM report_detailed;


-- The stored status agrees with the return date of each rental.
SELECT
    'rental_status agrees with return_date' AS test_case,
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE rental_status IS DISTINCT FROM
            CASE WHEN return_date IS NULL THEN 'Outstanding' ELSE 'Returned' END
    ) AS failures,
    CASE
        WHEN COUNT(*) > 0
            AND COUNT(*) FILTER (
                WHERE rental_status IS DISTINCT FROM
                    CASE WHEN return_date IS NULL THEN 'Outstanding' ELSE 'Returned' END
            ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM report_detailed;


-- Both statuses occur, so the nullable `return_date` is exercised.
SELECT
    'Both statuses stored' AS test_case,
    COUNT(*) FILTER (WHERE rental_status = 'Outstanding' AND return_date IS NULL) AS outstanding_rows,
    COUNT(*) FILTER (WHERE rental_status = 'Returned' AND return_date IS NOT NULL) AS returned_rows,
    CASE
        WHEN COUNT(*) FILTER (WHERE rental_status = 'Outstanding' AND return_date IS NULL) > 0
            AND COUNT(*) FILTER (WHERE rental_status = 'Returned' AND return_date IS NOT NULL) > 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM report_detailed;


-- The stored customer name matches the function applied to the customer.
SELECT
    'customer_name matches fn_customer_name' AS test_case,
    COUNT(*) AS rows_checked,
    COUNT(*) FILTER (
        WHERE d.customer_name IS DISTINCT FROM fn_customer_name(c.first_name, c.last_name)
    ) AS failures,
    CASE
        WHEN COUNT(*) > 0
            AND COUNT(*) FILTER (
                WHERE d.customer_name IS DISTINCT FROM fn_customer_name(c.first_name, c.last_name)
            ) = 0
            THEN 'PASS'
        ELSE 'FAIL'
    END AS result

FROM report_detailed AS d
    INNER JOIN customer AS c
        ON c.customer_id = d.customer_id;


-- A sample of the stored rows, outstanding rentals first.
SELECT *
FROM report_detailed
ORDER BY (return_date IS NOT NULL), rental_id
LIMIT 10;


-- Undo everything: the inserted rows, the original rows of the table and
-- the helper objects.
ROLLBACK;
