import { Link } from "react-router-dom";

export default function Sidebar() {
  return (
    <aside
      style={{
        width: "220px",
        background: "#111827",
        color: "white",
        padding: "20px",
      }}
    >
      <h2>BlueFox-Nexus</h2>

      <nav
        style={{
          display: "flex",
          flexDirection: "column",
          gap: "10px",
          marginTop: "20px",
        }}
      >
        <Link to="/">Dashboard</Link>
        <Link to="/events">Events</Link>
        <Link to="/alerts">Alerts</Link>
        <Link to="/devices">Devices</Link>
        <Link to="/metrics">Metrics</Link>
      </nav>
    </aside>
  );
}