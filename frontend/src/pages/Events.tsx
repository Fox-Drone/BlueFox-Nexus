import { useEffect, useState } from "react";
import { getEvents } from "../services/events";
import type { Event } from "../services/events";

export default function Events() {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const data = await getEvents();
        setEvents(data);
      } catch (err: any) {
        if (err?.response) {
          setError(`API Error ${err.response.status}`);
        } else {
          setError("Backend unreachable");
        }
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  return (
    <div className="p-6">
      {/* HEADER */}
      <h1 className="text-2xl font-semibold mb-4">Events</h1>

      {/* STATES */}
      {loading && (
        <div className="text-blue-400">⏳ Loading events...</div>
      )}

      {error && (
        <div className="bg-red-900 text-red-200 p-3 rounded mb-4">
          ❌ {error}
        </div>
      )}

      {/* TABLE */}
      {!loading && !error && (
        <div className="bg-gray-900 rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="text-gray-400 border-b border-gray-800">
              <tr>
                <th className="p-3 text-left">Time</th>
                <th className="p-3 text-left">Source</th>
                <th className="p-3 text-left">Level</th>
                <th className="p-3 text-left">Message</th>
              </tr>
            </thead>

            <tbody>
              {events.map((e) => (
                <tr
                  key={e.id}
                  className="border-b border-gray-800 hover:bg-gray-800/40"
                >
                  <td className="p-3">
                    {new Date(e.timestamp).toLocaleString()}
                  </td>
                  <td className="p-3">{e.source}</td>
                  <td className="p-3">
                    <span
                      className={
                        e.severity === "error"
                          ? "text-red-400"
                          : e.severity === "warning"
                          ? "text-yellow-400"
                          : "text-green-400"
                      }
                    >
                      {e.severity}
                    </span>
                  </td>
                  <td className="p-3">{e.message}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* EMPTY STATE */}
      {!loading && !error && events.length === 0 && (
        <div className="text-gray-500 mt-4">
          No events available
        </div>
      )}
    </div>
  );
}