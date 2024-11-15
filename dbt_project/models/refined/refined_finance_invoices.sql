{{ config(schema='refined_data') }}

WITH object_data AS (
    SELECT DISTINCT
        (payload::json ->> 'id')::numeric AS id,
        (payload::json ->> 'date')::date AS date,
        EXTRACT(MONTH FROM (payload::json ->> 'date')::date) AS month,
        payload::json ->> 'currency' AS currency,
        (payload::json ->> 'amount')::numeric AS original_amount,
        (payload::json ->> 'amount')::numeric * COALESCE(rcr.usd_rate, 1) AS amount_usd,
        UPPER(payload::json ->> 'department') AS department,
        payload::json ->> 'comment' AS comment
    FROM 
        {{ source('raw_data', 'raw_finance_invoice') }}  rfi
    LEFT JOIN 
        {{ source('raw_data', 'raw_currency_rate') }}  rcr
    ON 
        (payload::json ->> 'currency') = rcr.currency_code
    WHERE 
        payload IS NOT NULL
        AND json_typeof(payload::json) = 'object'
),
array_data AS (
    SELECT DISTINCT
        (e ->> 'id')::numeric AS id,
        (e ->> 'date')::date AS date,
        EXTRACT(MONTH FROM (e ->> 'date')::date) AS month,
        e ->> 'currency' AS currency,
        (e ->> 'amount')::numeric AS original_amount,
        (e ->> 'amount')::numeric * COALESCE(rcr.usd_rate, 1) AS amount_usd,
        UPPER(e ->> 'department') AS department,
        e ->> 'comment' AS comment
    FROM 
        {{ source('raw_data', 'raw_finance_invoice') }} rfi,
        json_array_elements(payload::json) AS e
    LEFT JOIN 
        {{ source('raw_data', 'raw_currency_rate') }} rcr 
    ON 
        (e ->> 'currency') = rcr.currency_code
    WHERE 
        payload IS NOT NULL
        AND json_typeof(payload::json) = 'array'
)
SELECT DISTINCT * 
FROM (
    SELECT * FROM object_data
    UNION ALL
    SELECT * FROM array_data
) combined_data
