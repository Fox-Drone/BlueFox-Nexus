import { useEffect, useState } from "react";
import { getAlerts } from "../services/alerts";
import type { Alert } from "../services/alerts";

export default function Alerts() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        const data = await getAlerts();
        setAlerts(data);
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

  function getSeverityColor(severity: string) {
    switch (severity.toLowerCase()) {
      case "critical":
        return "text-red-500";

      case "high":
      case "error":
        return "text-red-400";

      case "medium":
      case "warning":
        return "text-yellow-400";

      case "low":
      case "info":
        return "text-green-400";

      default:
        return "text-gray-400";
    }
  }

  return (
    <div className="p-6">
      {/* HEADER */}
      <h1 className="text-2xl font-semibold mb-4">Alerts</h1>

      {/* STATES */}
      {loading && (
        <div className="text-blue-400">
          ⏳ Loading alerts...
        </div>
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
                <th className="p-3 text-left">Host</th>
                <th className="p-3 text-left">Type</th>
                <th className="p-3 text-left">Severity</th>
                <th className="p-3 text-left">Message</th>
              </tr>
            </thead>

            <tbody>
              {alerts.map((alert) => (
                <tr
                  key={alert.id}
                  className="border-b border-gray-800 hover:bg-gray-800/40"
                >
                  <td className="p-3">
                    {new Date(alert.timestamp).toLocaleString()}
                  </td>

                  <td className="p-3">
                    {alert.host}
                  </td>

                  <td className="p-3">
                    {alert.alert_type}
                  </td>

                  <td className="p-3">
                    <span className={getSeverityColor(alert.severity)}>
                      {alert.severity}
                    </span>
                  </td>

                  <td className="p-3">
                    {alert.message}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* EMPTY */}
      {!loading && !error && alerts.length === 0 && (
        <div className="text-gray-500 mt-4">
          No alerts available
        </div>
      )}
    </div>
  );
}