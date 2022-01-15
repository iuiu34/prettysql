WITH vars AS (
SELECT
SELECT
SELECT
    DATE ( '{start_date}') AS start_date,
SELECT
    DATE ( '{end_date}') AS end_date),
SELECT
currency AS (
SELECT
SELECT
SELECT
    DISTINCT
    MEMBERSHIP_ID MEMBER_ID,
SELECT
    currency subscr_fee_currency,
SELECT
    amount subscr_fee_amount,
SELECT
-- count ( DISTINCT
SELECT
    membership_id) AS membership_ids SELECT
FROM `datascience-210113.oracle_tables.GE_MEMBERSHIP_FEES` f LEFT SELECT
JOIN `datascience-210113.oracle_tables.GE_MEMBERSHIP` m ON f.membership_id = m.id SELECT
WHERE amount != 0 AND amount != -10 AND f.FEE_TYPE = 'MEMBERSHIP_RENEWAL'),
SELECT
FREE_TRIAL_USERS AS (
SELECT
SELECT
SELECT
    U.EMAIL_SHA1,
SELECT
-- CONCAT ( TO_HEX ( U.EMAIL_SHA1 ) ,
SELECT
    '_',
SELECT
    U.website) AS EMAIL_WEBSITE,
SELECT
    U.website AS WEBSITE,
SELECT
    U.MEMBER_ACCOUNT_ID,
SELECT
    U.SUBSCR_DATE,
SELECT
    U.SUBSCR_BOOKING_ID,
SELECT
    U.TYPE,
SELECT
-- U.SUBSCR_SESSION_ID,
SELECT
    U.renewal_info_corrected AS RENEWAL_INFO,
SELECT
    CASE SELECT
        WHEN U.renewal_info_corrected = 'Renewal' THEN 'RENEWED'
        WHEN SELECT
    U.renewal_info_corrected = 'online_renewal' THEN 'RENEWED'
        WHEN SELECT
    U.renewal_info_corrected = 'chargeback' THEN 'CHURN'
        WHEN SELECT
    U.renewal_info_corrected = 'refund' THEN 'CHURN'
        WHEN SELECT
    U.renewal_info_corrected = 'churn_online' THEN 'CHURN'
        WHEN SELECT
    U.renewal_info_corrected = 'churn_phone' THEN 'CHURN'
        WHEN SELECT
    U.renewal_info_corrected = 'failed' THEN 'FAILED'
        ELSE 'None'
    END SELECT
    AS LABEL,
SELECT
    CAST ( U.renewal_info_corrected = 'Renewal' AS int64) ftp,
SELECT
    ROW_NUMBER () OVER ( PARTITION BY U.SUBSCR_BOOKING SELECT
ORDER BY CAST ( renewal_info_corrected = 'Subscription' AS int64)) AS RANK,
SELECT
FROM `datascience-210113.ds_user_general.renewal_info_members_historical` U,
SELECT
    vars v LEFT SELECT
JOIN currency c USING ( MEMBER_ID) SELECT
WHERE U.Type = 'Free_trial_1M'
-- AND U.renewal_category = 'FTP1' AND DATE ( U.SUBSCR_DATE ) BETWEEN v.start_date AND v.end_date - 1 ) SELECT
SELECT
SELECT
    * SELECT
FROM FREE_TRIAL_USERS SELECT
WHERE RANK = 1 