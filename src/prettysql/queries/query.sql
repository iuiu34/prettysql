WITH vars AS (
SELECT
    DATE('{start_date}') AS start_date,
    DATE('{end_date}') AS end_date ),
currency AS (
SELECT
    DISTINCT
    MEMBERSHIP_ID MEMBER_ID,
    currency subscr_fee_currency,
    amount subscr_fee_amount,
    --count (DISTINCT
    membership_id) AS membership_ids
FROM `datascience-210113.oracle_tables.GE_MEMBERSHIP_FEES` f
LEFT JOIN `datascience-210113.oracle_tables.GE_MEMBERSHIP` m
    ON
    f.MEMBERSHIP_ID = m.id
WHERE amount != 0
    AND amount != -10
    AND f.FEE_TYPE = 'MEMBERSHIP_RENEWAL' ),
FREE_TRIAL_USERS AS (
SELECT
    U.EMAIL_SHA1,
    --CONCAT(TO_HEX(U.EMAIL_SHA1),
    '_',
    U.website) AS EMAIL_WEBSITE,
    U.website AS WEBSITE,
    U.MEMBER_ACCOUNT_ID,
    U.SUBSCR_DATE,
    U.SUBSCR_BOOKING_ID,
    U.TYPE,
    --U.SUBSCR_SESSION_ID,
    U.renewal_info_corrected AS RENEWAL_INFO,
    CASE
        WHEN U.renewal_info_corrected = 'Renewal' THEN 'RENEWED'
        WHEN U.renewal_info_corrected = 'online_renewal' THEN 'RENEWED'
        WHEN U.renewal_info_corrected = 'chargeback' THEN 'CHURN'
        WHEN U.renewal_info_corrected = 'refund' THEN 'CHURN'
        WHEN U.renewal_info_corrected = 'churn_online' THEN 'CHURN'
        WHEN U.renewal_info_corrected = 'churn_phone' THEN 'CHURN'
        WHEN U.renewal_info_corrected = 'failed' THEN 'FAILED'
        ELSE 'None'
    END AS LABEL,
    CAST(U.renewal_info_corrected = 'Renewal' AS int64) ftp,
    ROW_NUMBER() OVER(PARTITION BY U.SUBSCR_BOOKING ORDER BY CAST(renewal_info_corrected = 'Subscription' AS int64)) AS RANK,
FROM `datascience-210113.ds_user_general.renewal_info_members_historical` U,
    vars v
LEFT JOIN currency c
    USING (MEMBER_ID)
WHERE U.Type = 'Free_trial_1M' --AND U.renewal_category = 'FTP1'
    AND DATE(U.SUBSCR_DATE) BETWEEN v.start_date
    AND v.end_date - 1 )
SELECT
    *
FROM FREE_TRIAL_USERS
WHERE RANK = 1