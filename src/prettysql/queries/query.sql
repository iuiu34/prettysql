CREATE TEMP FUNCTION BINULL(x float64, y float64) AS (
    IFNULL(NULLIF(x, -2), y)
    );
WITH constant AS (
SELECT
    -- comment
    DATE('2018-01-01') start_date,
    CURRENT_DATE() end_date,
    -- current_date() end_prime_ftp_date,
    ['a'] letters,
    [1,2,3] numbers,
    ),
test_aux as (
select 1 a, 'a' b, 0 c union all
select 2 a, 'b' b, 0 c union all
select 3 a, 'c' b, 0 c

)
test AS (
SELECT
    * except(c),
    count(*) c
FROM test_aux
    constant c
WHERE letters IN unnest(c.letters)
    AND issued = 1
    AND NULLIF(EMAIL_BUYER, '-2') IS NOT NULL
    AND DATE(DATE_REQUEST) BETWEEN c.start_date AND c.end_date
GROUP BY
    1, 2
    )
  select *
  from test