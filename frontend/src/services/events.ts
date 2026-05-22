import { api } from "./api";

export type Event = {
  id: string;
  source: string;
  host: string;
  timestamp: string;
  event_type: string;
  severity: string;
  message: string;
  tags: string[];
};

export async function getEvents() {
  const res = await api.get<Event[]>("/events");
  return res.data;
}