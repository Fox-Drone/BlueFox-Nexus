import { getEvents } from "./events";
import { getAlerts } from "./alerts";

export interface DashboardStats {
  events: number;
  alerts: number;
  devices: number;
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const [events, alerts] = await Promise.all([
    getEvents(),
    getAlerts(),
  ]);

  return {
    events: events.length,
    alerts: alerts.length,
    devices: 0,
  };
}