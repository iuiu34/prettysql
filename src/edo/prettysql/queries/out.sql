WITH vars AS (
SELECT
    DATE('{start_date}') AS start_date,
    DATE('{end_date}') AS end_date,
    26 AS month_in_x ),
sessions AS (
SELECT
    market,
    website,
    type,
    fullVisitorId,
    ga_visit_id,
    session_id,
    session_date,
    eventLabel,
    CASE
        WHEN ( eventLabel LIKE ('%:log_%') OR eventLabel LIKE ('%:prime-log_%') OR eventLabel LIKE ('%:no-prime-log_&') OR eventLabel LIKE ('%:prime-std-log_%') ) THEN 1
        ELSE 0
    END AS is_logged,
    CASE
        WHEN ( eventLabel LIKE ('%prime_widget_sce:%') ) THEN 1
        ELSE 0
    END AS is_see_widget,
    CASE
        WHEN ( eventLabel LIKE ('%know_more_banner_sce:%') OR eventLabel LIKE ('%know_more_selection_sce:%') OR eventLabel LIKE ('%know_more_widget_sce:%') OR REGEXP_CONTAINS(eventLabel, r'^know_more_list_[[:alnum:]]_sce:') OR eventLabel LIKE ('%know_more_selection_sce:%') OR eventLabel LIKE ('%know_more_selection_continue%') ) THEN 1
        ELSE 0
    END AS is_know_more,
    CASE
        WHEN ( eventLabel LIKE ('%know_more_banner_close_sce:%') OR eventLabel LIKE ('%know_more_selection_close_sce:%') OR eventLabel LIKE ('%know_more_widget_close_sce:%') OR eventLabel LIKE ('%know_more_list_close_sce:%') OR eventLabel LIKE ('%know_more_selection_close%') ) THEN 1
        ELSE 0
    END AS is_know_more_close,
    CASE
        WHEN ( eventLabel LIKE ('%_benefit%') ) THEN 1
        ELSE 0
    END AS is_benefit,
    CASE
        WHEN ( eventLabel LIKE ('%prime_terms_conditions_sce:%') OR eventLabel LIKE ('%prime_terms_conditions_pag:%') OR eventLabel LIKE ('%prime_terms_sce:%') OR eventLabel LIKE ('%unlocked_terms_and_conditions_sce:%') ) THEN 1
        ELSE 0
    END AS is_tc,
    CASE
        WHEN ( eventLabel LIKE ('%prime_fare_click_sce:%') OR eventLabel LIKE ('%prime_click_sce:%') OR eventLabel LIKE ('%prime-log_click_sce:%') ) THEN 1
        ELSE 0
    END AS is_prime_fare,
    CASE
        WHEN ( eventLabel LIKE ('%standard_fare_click_sce:%') OR eventLabel LIKE ('%full_fare_click_sce:%') OR eventLabel LIKE ('%no-prime_click_sce:%') OR eventLabel LIKE ('%no-prime-log_click_sce:%') ) THEN 1
        ELSE 0
    END AS is_standard_fare,
    CASE
        WHEN ( eventLabel LIKE ('%existing_account_log_in_sce:prime%') ) THEN 1
        ELSE 0
    END AS is_account_login,
    CASE
        WHEN ( eventLabel LIKE ('%prime_go_login_sce:%')
    OR eventLabel LIKE ('%prime_login_pag:%') ) THEN 1
        ELSE 0
    END AS is_prime_login,
    CASE
        WHEN ( eventLabel LIKE ('%prime_search_pag:%') ) THEN 1
        ELSE 0
    END AS is_prime_search,
FROM `{project}.{dataset}.ftp_historical_sessions_ga_aux`
WHERE eventLabel LIKE ('%prime_widget_sce:%')
    OR eventLabel LIKE ('%_click_sce:%')
    OR eventLabel LIKE ('%know_more_selection_sce:%')
    OR REGEXP_CONTAINS(eventLabel, r'^know_more_list_[[:alnum:]]_sce:')
    OR eventLabel LIKE ('%know_more_banner_sce:%')
    OR eventLabel LIKE ('%know_more_widget_sce:%')
    OR eventLabel LIKE ('%kknow_more_selection_continue%')
    OR eventLabel LIKE ('%know_more_banner_close_sce:%')
    OR eventLabel LIKE ('%know_more_list_close_sce:%')
    OR eventLabel LIKE ('%know_more_selection_close_sce:%')
    OR eventLabel LIKE ('%know_more_widget_close_sce:%')
    OR eventLabel LIKE ('%know_more_selection_close%')
    OR eventLabel LIKE ('%prime_terms_conditions_sce:%')
    OR eventLabel LIKE ('%prime_terms_conditions_pag:%')
    OR eventLabel LIKE ('%prime_terms_sce:%')
    OR eventLabel LIKE ('%unlocked_terms_and_conditions_sce:%')
    OR eventLabel LIKE ('%_benefit%')
    OR eventLabel LIKE ('%prime_search_pag:%')
    OR eventLabel LIKE ('%prime_login_pag:%')
    OR eventLabel LIKE ('%prime_go_login_sce:%')
    OR eventLabel LIKE ('%existing_account_log_in_sce:prime%') ),
sessions_ftp AS (
SELECT
    U.SUBSCR_BOOKING_ID,
    U.SUBSCR_DATE,
    GA.*
FROM `{project}.{dataset}.ftp_users` U,
    vars v
LEFT JOIN `datascience-210113.ds_user_general.user_info` UI
    USING
    (email_sha1),
    UNNEST( UI.OTHER_IDS.FULL_VISITOR_ID) fullVisitorId
JOIN sessions GA
    USING
    (fullVisitorId)
WHERE DATE(UI.PROCESSING_DATE) BETWEEN DATE_SUB(DATE(U.SUBSCR_DATE), INTERVAL v.month_in_x MONTH)
    AND DATE(U.SUBSCR_DATE)
    AND DATE(UI.PROCESSING_DATE) BETWEEN DATE_SUB(DATE(v.start_date), INTERVAL v.month_in_x MONTH)
    AND v.end_date
    AND DATE(GA.session_date) BETWEEN DATE_SUB(DATE(U.SUBSCR_DATE), INTERVAL v.month_in_x MONTH)
    AND DATE(U.SUBSCR_DATE)
    AND DATE(GA.session_date) BETWEEN DATE_SUB(v.start_date, INTERVAL v.month_in_x MONTH)
    AND v.end_date
    AND ARRAY_LENGTH(OTHER_IDS.FULL_VISITOR_ID) > 0 )
SELECT
    SUBSCR_BOOKING_ID,
    SUBSCR_DATE,
    SUM(is_logged) / COUNT(DISTINCT ga_visit_id) AS ratio_log,
    SUM(is_see_widget) AS is_see_widget,
    SUM(is_know_more) AS is_know_more,
    SUM(is_benefit) AS is_benefit,
    SUM(is_tc) AS is_tc,
    SUM(is_prime_fare) AS is_prime_fare,
    SUM(is_standard_fare) AS is_standard_fare,
    SUM(is_account_login) AS is_account_login,
    SUM(is_prime_login) AS is_prime_login,
    SUM(is_prime_search) AS is_prime_search,
FROM sessions_ftp
GROUP BY
    1, 2 