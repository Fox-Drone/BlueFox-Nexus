use crate::models::alert::Alert;

use sqlx::PgPool;

pub async fn insert_alert(pool: &PgPool, alert: &Alert) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        INSERT INTO alerts (
            id,
            event_id,
            rule_name,
            alert_type,
            severity,
            message,
            status,
            host,
            created_at
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8, NOW())
        "#,
        alert.id,
        alert.event_id,
        alert.rule_name,
        alert.alert_type,
        alert.severity.to_string(),
        alert.message,
        alert.status,
        alert.host
    )
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn get_alerts(
    pool: &PgPool,
    host: Option<String>,
    severity: Option<String>,
    limit: i64,
    offset: i64,
) -> Result<Vec<Alert>, sqlx::Error> {
    let mut query = sqlx::QueryBuilder::new("SELECT * FROM alerts WHERE 1=1");

    if let Some(host) = host {
        query.push(" AND host = ");
        query.push_bind(host);
    }

    if let Some(severity) = severity {
        query.push(" AND severity = ");
        query.push_bind(severity);
    }

    query.push(" ORDER BY created_at DESC LIMIT ");
    query.push_bind(limit);
    query.push(" OFFSET ");
    query.push_bind(offset);

    query.build_query_as::<Alert>().fetch_all(pool).await
}
