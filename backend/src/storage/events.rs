use crate::models::event::Event;

use sqlx::PgPool;

pub async fn insert_event(pool: &PgPool, event: &Event) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        INSERT INTO events (
            id, 
            source, 
            host, 
            event_type, 
            severity, 
            message, 
            tags, 
            timestamp
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        "#,
        event.id,
        event.source,
        event.host,
        event.event_type,
        format!("{:?}", event.severity),
        event.message,
        &event.tags,
        event.timestamp
    )
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn get_events(
    pool: &PgPool,
    host: Option<String>,
    severity: Option<String>,
    limit: i64,
    offset: i64,
) -> Result<Vec<Event>, sqlx::Error> {
    let mut query = sqlx::QueryBuilder::new("SELECT * FROM events WHERE 1=1");

    if let Some(host) = host {
        query.push(" AND host = ");
        query.push_bind(host);
    }

    if let Some(severity) = severity {
        query.push(" AND severity = ");
        query.push_bind(severity);
    }

    query.push(" ORDER BY timestamp DESC LIMIT ");
    query.push_bind(limit);
    query.push(" OFFSET ");
    query.push_bind(offset);

    query.build_query_as::<Event>().fetch_all(pool).await
}
