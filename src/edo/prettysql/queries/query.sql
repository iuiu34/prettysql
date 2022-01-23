CREATE TEMP FUNCTION BINULL(x float64, y float64) AS (
    IFNULL(NULLIF(x, -2), y)
    );
WITH constant AS (
SELECT
    -- comment
    DATE('2018-01-01') start_date,
    CURRENT_DATE() end_date,
    -- current_date() end_prime_ftp_date,
    ['Direct', 'Metasearch', 'CRM', 'Partners', 'Affiliate Networks', 'Paid Search non branded',
    'SEO', 'Paid Search branded', 'Others'] channel,
    ['Metasearch', 'Paid Search non branded'] channel_paid,
    ['App', 'Direct', 'CRM', 'SEO',
    'Paid Search branded'] channel_cheap,
    DATE('2019-01-01') prime_data_date,
    24 AS months_new,
    ),
blacklist AS (
SELECT
    email_buyer, COUNT(*) n
FROM `bi-pro-225314.bi_ora_ext.v_r_trd_ud_order`,
    constant c
WHERE DESC_PRODUCT IN ( 'DP', 'Flight' )
    AND issued = 1
    AND NULLIF(EMAIL_BUYER, '-2') IS NOT NULL
    AND DATE(DATE_REQUEST) BETWEEN c.start_date AND c.end_date
GROUP BY
    1
HAVING n > 200
    ),
ed_booking_customer_hist AS (
-- hist issued with product in (DP,Flight)
-- bi data only has data > 2017-01-01
SELECT
    DISTINCT
    u.email_sha1,
    u.timestamp,
    u.booking_id,
    CONCAT(u.email_sha1, u.timestamp, u.booking_id)
FROM `datascience-210113.oracle_tables.ED_BOOKING_CUSTOMER` u,
    constant c
JOIN `datascience-210113.oracle_tables.ED_BOOKING` cp
    ON u.booking_id = cp.id
JOIN `datascience-210113.oracle_tables.FI_BOOKING_ITEM` i
    ON i.booking_id = u.booking_id
WHERE cp.STATUS = 'CONTRACT'
    AND DATE(u.timestamp) BETWEEN DATE_SUB(c.start_date, INTERVAL c.months_new month)
    AND c.end_date
    AND DATE(cp.timestamp) BETWEEN DATE_SUB(c.start_date, INTERVAL c.months_new month)
    AND c.end_date
    AND DATE(i.timestamp) BETWEEN DATE_SUB(c.start_date, INTERVAL c.months_new month)
    AND c.end_date
    ),
new_user AS (
SELECT
    CAST(u1.BOOKING_ID AS string) bookingid,
    0 new_user,
    COUNT(distinct u0.booking_id) num_bookings
FROM ed_booking_customer_hist u1,
    constant c
JOIN ed_booking_customer_hist u0
    ON u1.EMAIL_SHA1 = u0.EMAIL_SHA1
WHERE DATE(u1.TIMESTAMP) >= c.start_date
    AND DATE(u0.TIMESTAMP) >= DATE_SUB(DATE(u1.TIMESTAMP), INTERVAL c.months_new month)
    AND u0.TIMESTAMP < u1.TIMESTAMP
GROUP BY 1, 2, 3
    ),
bi AS (
SELECT
    bi.*
    EXCEPT (
    REVENUEMARGIN,
    NETREVENUEMARGIN,
    MARGINALPROFIT,
    is_prime_free_trial,
    is_prime,
    is_first_prime),
    BINULL(is_prime_free_trial, 0) is_prime_free_trial,
    BINULL(is_prime, 0) is_prime,
    BINULL(is_first_prime, 0) is_first_prime,
    REVENUEMARGIN - IF(DATE(date_request) > c.prime_data_date, PRIMERECOGNIZEDSUBFEE,
    PRIMESUBSCRIPTIONFEEALLOCATED) REVENUEMARGIN,
    NETREVENUEMARGIN - IF(DATE(date_request) > c.prime_data_date, PRIMERECOGNIZEDSUBFEE,
    PRIMESUBSCRIPTIONFEEALLOCATED) NETREVENUEMARGIN,
    ADJUSTEDNETREVENUEMARGINRESTAT - IF(DATE(date_request) > c.prime_data_date, PRIMERECOGNIZEDSUBFEE,
    PRIMESUBSCRIPTIONFEEALLOCATED) NETREVENUEMARGINADJUSTED,
    MARGINALPROFIT - IF(DATE(date_request) > c.prime_data_date, PRIMERECOGNIZEDSUBFEE,
    PRIMESUBSCRIPTIONFEEALLOCATED) MARGINALPROFIT,
    CAST(bi.id_cp_order AS string) bookingid,
    DATE(date_request) bookingdate,
    bi.id_agg_market market,
    bi.id_brand brand,
    bi.id_website website,
    CASE
        WHEN bi.DESC_INTERFACE_AGG IN ( 'App', 'Mobile', 'Desktop' )
    THEN
    bi.DESC_INTERFACE_AGG
        ELSE 'Desktop'
    END interface,
    CASE
        WHEN bi.DESC_INTERFACE_AGG LIKE 'App'
    THEN 'App'
        WHEN bi.desc_mkt_channel LIKE 'SEO%'
    THEN 'SEO'
        WHEN bi.desc_mkt_channel IN UNNEST (c.channel) THEN bi.desc_mkt_channel
        ELSE 'Others'
    END channel,
    CASE
        WHEN bi.desc_interface_agg LIKE 'App'
    THEN 'Cheap'
        WHEN bi.desc_mkt_channel LIKE 'SEO%'
    THEN 'Cheap'
        WHEN bi.desc_mkt_channel IN UNNEST ( c.channel_cheap) THEN 'Cheap'
        WHEN bi.desc_mkt_channel IN UNNEST ( c.channel_paid) THEN bi.desc_mkt_channel
        ELSE 'Others'
    END channel_group,
    DATE_TRUNC(DATE(date_request), MONTH) MONTH,
    u.email_sha1,
FROM `bi-pro-225314.bi_ora_ext.v_r_trd_ud_order` bi,
    constant c
JOIN `datascience-210113.oracle_tables.ED_BOOKING_CUSTOMER` u
    ON bi.id_cp_order = u.booking_id
JOIN `datascience-210113.oracle_tables.ED_BOOKING` cp
    ON bi.id_cp_order = cp.id
WHERE bi.issued = 1
    AND cp.status = 'CONTRACT'
    AND bi.DESC_PRODUCT IN ( 'Flight', 'DP' )
    AND DATE(bi.DATE_REQUEST) >= c.start_date
    AND DATE(u.timestamp) >= c.start_date
    AND DATE(cp.timestamp) >= c.start_date
    AND email_buyer NOT IN (
SELECT
    email_buyer FROM blacklist )
    ),
main AS (
SELECT
    bi.*,
    IFNULL(new_user.new_user, 1.0) new_user,
    IFNULL(new_user.num_bookings, 0) num_bookings,
    row_number() OVER(PARTITION BY bi.bookingid) row_number
FROM bi
LEFT JOIN new_user
    ON bi.bookingid = new_user.bookingid
    )
SELECT
    *
    EXCEPT (
    row_number)
FROM main
WHERE row_number = 1 