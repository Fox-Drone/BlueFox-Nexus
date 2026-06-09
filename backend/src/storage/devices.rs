use crate::models::device::Device;
use sqlx::PgPool;

pub async fn insert_device(pool: &PgPool, device: &Device) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        INSERT INTO devices (
            id,
            hostname,
            ip,
            os,
            tags,
            is_active,
            last_seen,
            metadata
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        "#,
        device.id,
        device.hostname,
        device.ip,
        device.os,
        &device.tags,
        device.is_active,
        device.last_seen,
        device.metadata
    )
    .execute(pool)
    .await?;

    Ok(())
}
