use crate::models::metric::Metric;
use sqlx::PgPool;

pub async fn insert_metric(pool: &PgPool, metric: &Metric) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        INSERT INTO metrics (
            id, host, metric_type, value, timestamp, source
        )
        VALUES ($1,$2,$3,$4,$5,$6)
        "#,
        metric.id,
        metric.host,
        metric.metric_type,
        metric.value,
        metric.timestamp,
        metric.source
    )
    .execute(pool)
    .await?;

    Ok(())
}
