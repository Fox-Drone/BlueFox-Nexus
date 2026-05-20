use crate::{
    core::dispatcher::Dispatcher, models::device::Device, models::event::Event,
    models::metric::Metric, rules::context::RuleContext,
};

#[derive(Clone)]
pub struct Pipeline {
    pub ctx: RuleContext,
    pub dispatcher: Dispatcher,
}

impl Pipeline {
    pub async fn process(&self, event: Event) {
        self.ctx.add_event(event.clone());

        let alerts = crate::rules::engine::process_event(&event, &self.ctx);

        self.dispatcher.handle(event, alerts).await;
    }

    pub async fn process_metric(&self, metric: Metric) {
        self.dispatcher.handle_metric(metric).await;
    }

    pub async fn process_device(&self, device: Device) {
        self.dispatcher.handle_device(device).await;
    }
}
