/*
Question: What are the highest-paying skills for data engineers?
- Calculate the median salary for each skill required in data engineer positions
- Focus on remote positions with specified salaries
- Include skill frequency to identify both salary and demand
*/

SELECT 
    sd.skills, 
    COUNT (*) as demand_frequency,
    MEDIAN(jf.salary_year_avg) as median_salary
 FROM job_postings_fact as jf
 INNER JOIN skills_job_dim as sjd ON jf.job_id = sjd.job_id
 INNER JOIN skills_dim as sd ON sjd.skill_id = sd.skill_id
 WHERE 
    job_title_short = 'Data Engineer' 
    AND job_work_from_home = TRUE
 GROUP BY 
    sd.skills
 HAVING 
    COUNT (*) > 100
 ORDER BY 
    median_salary DESC, demand_frequency DESC
 LIMIT 10;


 /*

 Here's a breakdown of the highest-paying skills for Data Engineers:

Key Insights:
- Rust remains the top-paying skill at $210K median salary, though demand is still relatively limited (232 postings).
- Terraform and Golang both have high median salaries at $184K, with strong demand (Terraform: 3,248 postings; Golang: 912 postings).
- Other notable skills with both high pay and moderate-to-high frequency include:
  - Spring: $175.5K median salary (364 postings)
  - Neo4j: $170K median salary (277 postings)
  - GDPR: $169.6K median salary (582 postings)
  - GraphQL: $167.5K median salary (445 postings)
  - Kubernetes: $150.5K median salary (4,202 postings)
  - Airflow: $150K median salary (9,996 postings)
- Bitbucket, Ruby, Redis, Ansible, and Jupyter all appear in the top 25 for pay, each with hundreds of postings.
- Most skills on the list are no longer extreme statistical outliers with just a handful of postings; instead, many show consistently strong demand.

Takeaway: While the very top-paying skill (Rust) still has less demand than major cloud and data tools, most of the top-paying skills have both solid salaries and significant demand. This suggests that learning tools like Terraform, Golang, Spring, Neo4j, and especially core data engineering tools (Airflow, Kubernetes) provides a strong balance between compensation and marketability.


 ┌───────────┬──────────────────┬───────────────┐
│  skills   │ demand_frequency │ median_salary │
│  varchar  │      int64       │    double     │
├───────────┼──────────────────┼───────────────┤
│ rust      │              232 │      210000.0 │
│ terraform │             3248 │      184000.0 │
│ golang    │              912 │      184000.0 │
│ spring    │              364 │      175500.0 │
│ neo4j     │              277 │      170000.0 │
│ gdpr      │              582 │      169615.5 │
│ zoom      │              127 │      168437.5 │
│ graphql   │              445 │      167500.0 │
│ mongo     │              265 │      162250.0 │
│ fastapi   │              204 │      157500.0 │
└───────────┴──────────────────┴───────────────┘
*/