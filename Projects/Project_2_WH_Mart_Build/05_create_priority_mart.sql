-- Step 5: Mart - Create priority roles mart (snapshot mart)

DROP SCHEMA IF EXISTS priority_mart CASCADE;

CREATE SCHEMA priority_mart;

SELECT '==== Loading roles for priority mart ====' AS info;
CREATE TABLE priority_mart.priority_roles (
    role_id         INTEGER     PRIMARY KEY,
    role_name       VARCHAR,
    priority_lvl    INTEGER
);

INSERT INTO priority_mart.priority_roles (
    role_id,
    role_name,
    priority_lvl 
)
VALUES
(1, 'Data Engineer',             2),
(2, 'Senior Data Engineer',      1),
(3, 'Software Engineer',         3);

SELECT * FROM priority_mart.priority_roles;

CREATE TABLE priority_mart.priority_jobs_snapshot (
    job_id              INTEGER     PRIMARY KEY,
    job_title_short     VARCHAR,
    company_name        VARCHAR,
    job_posted_date     TIMESTAMP,
    salary_year_avg     INTEGER,
    priority_lvl        INTEGER,
    updated_at          TIMESTAMP
);
INSERT INTO priority_mart.priority_jobs_snapshot (
    job_id,
    job_title_short,
    company_name,
    job_posted_date,
    salary_year_avg,
    priority_lvl,
    updated_at      
)
SELECT
    jpf.job_id,
    jpf.job_title_short,
    cd.name,
    jpf.job_posted_date,
    jpf.salary_year_avg,
    pr.priority_lvl,
    CURRENT_TIMESTAMP
FROM 
    job_postings_fact AS jpf
LEFT JOIN
    company_dim AS cd
    ON jpf.company_id = cd.company_id
INNER JOIN
    priority_mart.priority_roles AS pr
    ON jpf.job_title_short = pr.role_name;

SELECT 'Priority Roles Dimension' AS table_name, COUNT(*) AS record_count FROM priority_mart.priority_roles
UNION ALL
SELECT 'Priority Jobs Snapshot', COUNT(*) FROM priority_mart.priority_jobs_snapshot;

SELECT '==== Priority Roles Dimension Sample ====' AS info;
SELECT * FROM priority_mart.priority_roles LIMIT 3;

SELECT '==== Priority Jobs Snapshot Sample ====' AS info;
SELECT * FROM priority_mart.priority_jobs_snapshot LIMIT 3;

SELECT '==== Priority Jobs Snapshot With Agregation Sample ====' AS info;
SELECT 
    job_title_short,
    COUNT(*) AS job_count,
    MIN(priority_lvl) AS priority_lvl,
    MIN(updated_at) AS updated_at
FROM priority_mart.priority_jobs_snapshot          
GROUP BY job_title_short
ORDER BY job_count DESC;