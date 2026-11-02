-- Step 7: Mart - Create company hiring mart (dimensional mart with bridge tables)

DROP SCHEMA IF EXISTS company_mart CASCADE;

CREATE SCHEMA company_mart;

SELECT '==== Loading Job Title Short Dimension ====' AS info;
CREATE SEQUENCE company_mart.seq_jts START 1;
CREATE TABLE company_mart.dim_job_title_short (
    job_title_short_id  INTEGER     PRIMARY KEY DEFAULT nextval('company_mart.seq_jts'),
    job_title_short     VARCHAR
);

INSERT INTO company_mart.dim_job_title_short (job_title_short)
SELECT DISTINCT job_title_short
FROM job_postings_fact
ORDER BY job_title_short;

SELECT '==== Loading Job Title Dimension ====' AS info;
CREATE SEQUENCE company_mart.seq_jt START 1;
CREATE TABLE company_mart.dim_job_title (
    job_title_id    INTEGER     PRIMARY KEY DEFAULT nextval('company_mart.seq_jt'),
    job_title       VARCHAR
);

INSERT INTO company_mart.dim_job_title (job_title)
SELECT DISTINCT job_title
FROM job_postings_fact
WHERE job_title IS NOT NULL
ORDER BY job_title;

SELECT '==== Loading Company Dimension ====' AS info;
CREATE TABLE company_mart.dim_company (
    company_id      INTEGER     PRIMARY KEY,
    company_name    VARCHAR
);

INSERT INTO company_mart.dim_company (
    company_id,
    company_name
)
SELECT
    company_id,
    name
FROM company_dim;

SELECT '==== Loading Location Dimension ====' AS info;
CREATE SEQUENCE company_mart.seq_loc START 1;
CREATE TABLE company_mart.dim_location (
    location_id     INTEGER     PRIMARY KEY DEFAULT nextval('company_mart.seq_loc'),
    job_country     VARCHAR,
    job_location    VARCHAR
);

-- NULL countries/locations are kept on purpose
INSERT INTO company_mart.dim_location (
    job_country,
    job_location
)
SELECT DISTINCT
    job_country,
    job_location
FROM job_postings_fact;

SELECT '==== Loading Date Month Dimension ====' AS info;
CREATE TABLE company_mart.dim_date_month (
    month_start_date    DATE    PRIMARY KEY,
    year                INTEGER,
    month               INTEGER
);

INSERT INTO company_mart.dim_date_month (
    month_start_date,
    year,
    month
)
SELECT DISTINCT
    DATE_TRUNC('month', job_posted_date) AS month_start_date,
    EXTRACT(YEAR FROM job_posted_date) AS year,
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM job_postings_fact
ORDER BY month_start_date;

SELECT '==== Loading Job Title Bridge ====' AS info;
CREATE TABLE company_mart.bridge_job_title (
    job_title_short_id  INTEGER,
    job_title_id        INTEGER,
    PRIMARY KEY (job_title_short_id, job_title_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short(job_title_short_id),
    FOREIGN KEY (job_title_id) REFERENCES company_mart.dim_job_title(job_title_id)
);

INSERT INTO company_mart.bridge_job_title (
    job_title_short_id,
    job_title_id
)
WITH dedouble_job_postings AS (
    SELECT DISTINCT
        job_title_short,
        job_title
    FROM job_postings_fact
)
SELECT
    djts.job_title_short_id,
    djt.job_title_id
FROM
    dedouble_job_postings AS djp
JOIN
    company_mart.dim_job_title_short AS djts
    ON djp.job_title_short = djts.job_title_short
JOIN
    company_mart.dim_job_title AS djt
    ON djp.job_title = djt.job_title;

SELECT '==== Loading Company Location Bridge ====' AS info;
CREATE TABLE company_mart.bridge_company_location (
    company_id      INTEGER,
    location_id     INTEGER,
    PRIMARY KEY (company_id, location_id),
    FOREIGN KEY (company_id) REFERENCES company_mart.dim_company(company_id),
    FOREIGN KEY (location_id) REFERENCES company_mart.dim_location(location_id)
);

INSERT INTO company_mart.bridge_company_location (
    company_id,
    location_id
)
WITH dedouble_location_posts AS (
    SELECT DISTINCT
        company_id,
        job_country,
        job_location
    FROM job_postings_fact
)
SELECT
    dc.company_id,
    dl.location_id
FROM
    dedouble_location_posts AS dlp
JOIN
    company_mart.dim_company AS dc
    ON dlp.company_id = dc.company_id
JOIN
    company_mart.dim_location AS dl
    -- IS NOT DISTINCT FROM so NULL locations still match
    ON dlp.job_country IS NOT DISTINCT FROM dl.job_country
    AND dlp.job_location IS NOT DISTINCT FROM dl.job_location;

SELECT '==== Loading Company Hiring Monthly Fact ====' AS info;
CREATE TABLE company_mart.fact_company_hiring_monthly (
    company_id                  INTEGER,
    job_title_short_id          INTEGER,
    month_start_date            DATE,
    job_country                 VARCHAR,
    postings_count              INTEGER,
    median_salary_year          DOUBLE,
    min_salary_year             DOUBLE,
    max_salary_year             DOUBLE,
    remote_share                DOUBLE,
    health_insurance_share      DOUBLE,
    no_degree_mention_share     DOUBLE,
    PRIMARY KEY (company_id, job_title_short_id, month_start_date, job_country),
    FOREIGN KEY (company_id) REFERENCES company_mart.dim_company(company_id),
    FOREIGN KEY (job_title_short_id) REFERENCES company_mart.dim_job_title_short(job_title_short_id),
    FOREIGN KEY (month_start_date) REFERENCES company_mart.dim_date_month(month_start_date)
);

INSERT INTO company_mart.fact_company_hiring_monthly (
    company_id,
    job_title_short_id,
    month_start_date,
    job_country,
    postings_count,
    median_salary_year,
    min_salary_year,
    max_salary_year,
    remote_share,
    health_insurance_share,
    no_degree_mention_share
)
WITH job_posts_prep AS (
    SELECT
        company_id,
        job_title_short,
        DATE_TRUNC('month', job_posted_date) AS month_start_date,
        job_country,
        salary_year_avg,
        -- convert boolean flags (1 or 0)
        CASE WHEN job_work_from_home = TRUE THEN 1 ELSE 0 END AS is_remote,
        CASE WHEN job_health_insurance = TRUE THEN 1 ELSE 0 END AS has_health_insurance,
        CASE WHEN job_no_degree_mention = TRUE THEN 1 ELSE 0 END AS no_degree_mentioned
    FROM job_postings_fact
    -- job_country is part of the primary key, it can't be NULL
    WHERE job_country IS NOT NULL
)
SELECT
    jpp.company_id,
    djts.job_title_short_id,
    jpp.month_start_date,
    jpp.job_country,
    COUNT(*) AS postings_count,
    MEDIAN(jpp.salary_year_avg) AS median_salary_year,
    MIN(jpp.salary_year_avg) AS min_salary_year,
    MAX(jpp.salary_year_avg) AS max_salary_year,
    AVG(jpp.is_remote) AS remote_share,
    AVG(jpp.has_health_insurance) AS health_insurance_share,
    AVG(jpp.no_degree_mentioned) AS no_degree_mention_share
FROM
    job_posts_prep AS jpp
JOIN
    company_mart.dim_job_title_short AS djts
    ON djts.job_title_short = jpp.job_title_short
GROUP BY
    jpp.company_id,
    djts.job_title_short_id,
    jpp.month_start_date,
    jpp.job_country;

SELECT 'Job Title Short Dimension' AS table_name, COUNT(*) AS record_count FROM company_mart.dim_job_title_short
UNION ALL
SELECT 'Job Title Dimension', COUNT(*) FROM company_mart.dim_job_title
UNION ALL
SELECT 'Company Dimension', COUNT(*) FROM company_mart.dim_company
UNION ALL
SELECT 'Location Dimension', COUNT(*) FROM company_mart.dim_location
UNION ALL
SELECT 'Date Month Dimension', COUNT(*) FROM company_mart.dim_date_month
UNION ALL
SELECT 'Job Title Bridge', COUNT(*) FROM company_mart.bridge_job_title
UNION ALL
SELECT 'Company Location Bridge', COUNT(*) FROM company_mart.bridge_company_location
UNION ALL
SELECT 'Company Hiring Monthly Fact', COUNT(*) FROM company_mart.fact_company_hiring_monthly;

SELECT '==== Data Validation Checks ====' AS info;
SELECT
    'Job Title Short Dimension' AS check_name,
    (SELECT COUNT(*) FROM company_mart.dim_job_title_short) AS mart_count,
    (SELECT COUNT(DISTINCT job_title_short) FROM job_postings_fact) AS expected_count
UNION ALL
SELECT
    'Job Title Dimension',
    (SELECT COUNT(*) FROM company_mart.dim_job_title),
    (SELECT COUNT(DISTINCT job_title) FROM job_postings_fact)
UNION ALL
SELECT
    'Company Dimension',
    (SELECT COUNT(*) FROM company_mart.dim_company),
    (SELECT COUNT(*) FROM company_dim)
UNION ALL
SELECT
    'Location Dimension',
    (SELECT COUNT(*) FROM company_mart.dim_location),
    (SELECT COUNT(*) FROM (SELECT DISTINCT job_country, job_location FROM job_postings_fact))
UNION ALL
SELECT
    'Date Month Dimension',
    (SELECT COUNT(*) FROM company_mart.dim_date_month),
    (SELECT COUNT(DISTINCT DATE_TRUNC('month', job_posted_date)) FROM job_postings_fact)
UNION ALL
SELECT
    'Job Title Bridge',
    (SELECT COUNT(*) FROM company_mart.bridge_job_title),
    (SELECT COUNT(*) FROM (SELECT DISTINCT job_title_short, job_title FROM job_postings_fact WHERE job_title IS NOT NULL))
UNION ALL
SELECT
    'Company Location Bridge',
    (SELECT COUNT(*) FROM company_mart.bridge_company_location),
    (SELECT COUNT(*) FROM (SELECT DISTINCT company_id, job_country, job_location FROM job_postings_fact))
UNION ALL
SELECT
    'Fact Postings Sum',
    (SELECT SUM(postings_count) FROM company_mart.fact_company_hiring_monthly),
    (SELECT COUNT(*) FROM job_postings_fact WHERE job_country IS NOT NULL);

SELECT '==== Job Title Short Dimension Sample ====' AS info;
SELECT * FROM company_mart.dim_job_title_short ORDER BY job_title_short_id LIMIT 3;

SELECT '==== Job Title Dimension Sample ====' AS info;
SELECT * FROM company_mart.dim_job_title ORDER BY job_title_id LIMIT 3;

SELECT '==== Company Dimension Sample ====' AS info;
SELECT * FROM company_mart.dim_company LIMIT 3;

SELECT '==== Location Dimension Sample ====' AS info;
SELECT * FROM company_mart.dim_location ORDER BY location_id LIMIT 3;

SELECT '==== Date Month Dimension Sample ====' AS info;
SELECT * FROM company_mart.dim_date_month ORDER BY month_start_date LIMIT 3;

SELECT '==== Job Title Bridge Sample ====' AS info;
SELECT * FROM company_mart.bridge_job_title LIMIT 3;

SELECT '==== Company Location Bridge Sample ====' AS info;
SELECT * FROM company_mart.bridge_company_location LIMIT 3;

SELECT '==== Company Hiring Monthly Fact Sample ====' AS info;
SELECT * FROM company_mart.fact_company_hiring_monthly LIMIT 3;
