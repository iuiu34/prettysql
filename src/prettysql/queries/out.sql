WITH vars AS (
SELECT
    DATE('{start_date}') AS start_date,
    DATE('{end_date}') AS end_date ),
currency AS (
SELECT
    DISTINCT
    membership_id member_id,
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
free_trial_users AS (
SELECT
    u.email_sha1,
    --concat(to_hex(u.email_sha1),
    '_',
    u.website) AS email_website,
    u.website AS website,
    u.member_account_id,
    u.subscr_date,
    u.subscr_booking_id,
    u.type,
    --u.subscr_session_id,
    u.renewal_info_corrected AS renewal_info,
    case
    when u.renewal_info_corrected = 'renewal' then 'renewed'
    when u.renewal_info_corrected = 'online_renewal' then 'renewed'
    when u.renewal_info_corrected = 'chargeback' then 'churn'
    when u.renewal_info_corrected = 'refund' then 'churn'
    when u.renewal_info_corrected = 'churn_online' then 'churn'
    when u.renewal_info_corrected = 'churn_phone' then 'churn'
    when u.renewal_info_corrected = 'failed' then 'failed'
    else 'none'
    end AS label,
    CAST(U.renewal_info_corrected = 'Renewal' AS int64) ftp,
    ROW_NUMBER() OVER(PARTITION BY U.SUBSCR_BOOKING ORDER BY CAST(renewal_info_corrected = 'Subscription' AS int64)) AS RANK,
FROM `datascience-210113.ds_user_general.renewal_info_members_historical` U,
    vars v
LEFT JOIN currency c
    USING
    (MEMBER_ID)
WHERE U.Type = 'Free_trial_1M' --AND U.renewal_category = 'FTP1'
    AND DATE(U.SUBSCR_DATE) BETWEEN v.start_date
    AND v.end_date - 1 )
SELECT
    *
FROM FREE_TRIAL_USERS
WHERE RANK = 1