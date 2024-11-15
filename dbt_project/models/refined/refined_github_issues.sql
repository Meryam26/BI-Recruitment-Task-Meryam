WITH raw_data AS (
    SELECT 
        id,
        repository, 
        SPLIT_PART(repository, '/', 1) AS organization,
        SPLIT_PART(repository, '/', 2) AS repository_name,
        state, 
        created_at, 
        closed_at, 
        ("user"::jsonb)->>'login' AS created_by,
        (assignees::jsonb)->0->>'login' AS assigned_to,
        (labels::jsonb)->>'name' AS label_name,
        (milestone::jsonb)->>'title' AS milestone_title,
        (reactions::jsonb)->>'total_count' AS total_reactions,
        title,
        comments,
        (closed_at::timestamp - created_at::timestamp) AS resolution_time,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY closed_at DESC NULLS LAST) AS row_num 
    FROM {{ source('raw_data', 'raw_github_issues') }}
),
deduplicated_data AS (
    SELECT *
    FROM raw_data
    WHERE row_num = 1  
),
cleaned_data AS (
    SELECT 
        id,
        organization,
        repository_name,
        created_by, 
        assigned_to, 
        label_name, 
        milestone_title,
        comments,
        title, 
        state,
        total_reactions::int AS total_reactions,
        created_at::timestamp AS created_at,
        closed_at::timestamp AS closed_at,
        resolution_time
    FROM deduplicated_data
)
SELECT * 
FROM cleaned_data
