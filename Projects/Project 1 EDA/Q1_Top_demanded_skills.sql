 /*
 Question: What are the most in-demand skills for data engineers?
- Join job postings to inner join table similar to query 2
- Identify the top 10 in-demand skills for data engineers
- Focus on remote job postings
 */
 SELECT 
    sd.skills, 
    COUNT (*) as top_demanded_skills
 FROM job_postings_fact as jf
 INNER JOIN skills_job_dim as sjd ON jf.job_id = sjd.job_id
 INNER JOIN skills_dim as sd ON sjd.skill_id = sd.skill_id
 WHERE 
    job_title_short = 'Data Engineer' 
    AND job_work_from_home = TRUE
 GROUP BY 
    sd.skills
 ORDER BY 
    top_demanded_skills DESC
 LIMIT 10;


/*

Key takeaways:
- SQL and Python remain the foundational skills for data engineers
- Cloud platforms (AWS, Azure) are critical for modern data engineering
- Big data tools like Spark continue to be highly valued
- Data pipeline tools (Airflow, Snowflake, Databricks) show growing demand
- Java and GCP round out the top 10 most requested skills

┌────────────┬─────────────────────┐
│   skills   │ top_demanded_skills │
│  varchar   │        int64        │
├────────────┼─────────────────────┤
│ sql        │               29221 │
│ python     │               28776 │
│ aws        │               17823 │
│ azure      │               14143 │
│ spark      │               12799 │
│ airflow    │                9996 │
│ snowflake  │                8639 │
│ databricks │                8183 │
│ java       │                7267 │
│ gcp        │                6446 │
└────────────┴─────────────────────┘

*/




