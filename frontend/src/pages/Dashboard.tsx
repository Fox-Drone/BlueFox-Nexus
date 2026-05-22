import { useEffect, useState } from "react";

import {
  getDashboardStats,
  type DashboardStats,
} from "../services/dashboard";

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    events: 0,
    alerts: 0,
    devices: 0,
  });

  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const data = await getDashboardStats();
        setStats(data);
      } catch (err) {
        console.error("Dashboard stats error:", err);
      } finally {
        setLoading(false);
      }
    }

    fetchStats();
  }, []);

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* EVENTS */}
      <div className="bg-gray-900 p-5 rounded-lg border border-gray-800">
        <h2 className="text-gray-400 text-sm mb-2">
          Events
        </h2>

        <p className="text-3xl font-semibold text-white">
          {loading ? "..." : stats.events}
        </p>
      </div>

      {/* ALERTS */}
      <div className="bg-gray-900 p-5 rounded-lg border border-gray-800">
        <h2 className="text-gray-400 text-sm mb-2">
          Alerts
        </h2>

        <p className="text-3xl font-semibold text-white">
          {loading ? "..." : stats.alerts}
        </p>
      </div>

      {/* DEVICES */}
      <div className="bg-gray-900 p-5 rounded-lg border border-gray-800">
        <h2 className="text-gray-400 text-sm mb-2">
          Devices
        </h2>

        <p className="text-3xl font-semibold text-white">
          {loading ? "..." : stats.devices}
        </p>
      </div>
    </div>
  );
}