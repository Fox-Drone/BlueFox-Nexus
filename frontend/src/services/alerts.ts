import { api } from "./api";

export interface Alert {
  id: string;
  event_id?: string;
  alert_type: string;
  severity: string;
  message: string;
  timestamp: string;
  host: string;
}

export async function getAlerts(): Promise<Alert[]> {
  const res = await api.get("/alerts");
  return res.data;
}