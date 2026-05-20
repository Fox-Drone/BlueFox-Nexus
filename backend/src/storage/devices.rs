use crate::models::device::Device;
use sqlx::PgPool;

pub async fn insert_device(pool: &PgPool, device: &Device) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        INSERT INTO devices (
            id, hostname, ip, os, tags, is_active
        )
        VALUES ($1,$2,$3,$4,$5,$6)
        "#,
        device.id,
        device.hostname,
        device.ip,
        device.os,
        &device.tags,
        device.is_active
    )
    .execute(pool)
    .await?;

    Ok(())
}
