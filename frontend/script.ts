// Initialize histories with empty arrays
let cpuHistory: number[] = [];
let ramHistory: number[] = [];
let diskHistory: number[] = [];

// Canvas elements and contexts
const cpuCanvas = document.getElementById('cpuChart') as HTMLCanvasElement;
const cpuCtx = cpuCanvas.getContext('2d');
const ramCanvas = document.getElementById('ramChart') as HTMLCanvasElement;
const ramCtx = ramCanvas.getContext('2d');
const diskCanvas = document.getElementById('diskChart') as HTMLCanvasElement;
const diskCtx = diskCanvas.getContext('2d');

// Constants for chart drawing
const MAX_HISTORY: number = 60; // Keep last 60 samples
const CHART_WIDTH: number = cpuCanvas.width; // Assuming all canvases have the same width
const CHART_HEIGHT: number = cpuCanvas.height; // Assuming all canvases have the same height

// Utility function to push value to history and keep it within MAX_HISTORY
function pushValue(history: number[], value: number): void {
  value = Math.max(0, Math.min(100, value)); // Clamp value between 0 and 100
  history.push(value);
  if (history.length > MAX_HISTORY) {
    history.shift(); // Remove oldest value
  }
}

// Function to draw a single chart line
function drawChart(ctx: CanvasRenderingContext2D | null, history: number[], color: string): void {
  if (!ctx) return; // Exit if context is not available

  const step = Math.max(1, CHART_WIDTH / (MAX_HISTORY - 1));

  ctx.clearRect(0, 0, CHART_WIDTH, CHART_HEIGHT);
  // Background
  ctx.fillStyle = '#0b1220';
  ctx.fillRect(0, 0, CHART_WIDTH, CHART_HEIGHT);

  // Line
  if (history.length > 1) {
    ctx.lineWidth = 2;
    ctx.strokeStyle = color;
    ctx.beginPath();
    history.forEach((v, i) => {
      const x = i * step;
      // Invert y-axis for chart (higher value is lower on canvas)
      const y = CHART_HEIGHT - (v / 100) * CHART_HEIGHT;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();
  }
}

// --- Metric Fetching ---
async function fetchMetrics(): Promise<void> {
  try {
    const res = await fetch('http://0.0.0.0:3000/metrics');
    if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);

    // Define an interface for the expected metric data structure
    interface SystemMetrics {
      cpu_usage: number;
      ram_usage: number;
      disk_usage: number;
      net_in: number;
      net_out: number;
      timestamp: number;
    }

    const data: SystemMetrics = await res.json();

    // Update text content
    const cpuSpan = document.getElementById('cpu') as HTMLSpanElement;
    const ramSpan = document.getElementById('ram') as HTMLSpanElement;
    const diskSpan = document.getElementById('disk') as HTMLSpanElement;
    const netInSpan = document.getElementById('netIn') as HTMLSpanElement;
    const netOutSpan = document.getElementById('netOut') as HTMLSpanElement;
    const tsSpan = document.getElementById('ts') as HTMLSpanElement;

    if(cpuSpan) cpuSpan.textContent = data.cpu_usage.toFixed(2);
    if(ramSpan) ramSpan.textContent = data.ram_usage.toFixed(2);
    if(diskSpan) diskSpan.textContent = data.disk_usage.toFixed(2);
    if(netInSpan) netInSpan.textContent = data.net_in.toLocaleString();
    if(netOutSpan) netOutSpan.textContent = data.net_out.toLocaleString();
    if(tsSpan) tsSpan.textContent = new Date(data.timestamp * 1000).toLocaleString();

    // Push real data to history and draw charts
    pushValue(cpuHistory, data.cpu_usage);
    pushValue(ramHistory, data.ram_usage);
    pushValue(diskHistory, data.disk_usage);

    // Redraw all charts
    drawChart(cpuCtx, cpuHistory, '#4ae3ff'); // Blue color for CPU
    drawChart(ramCtx, ramHistory, '#ff4a4a'); // Red color for RAM
    drawChart(diskCtx, diskHistory, '#4aff4a'); // Green color for Disk

  } catch (e) {
    console.error("Failed to fetch metrics:", e);
    // Optionally update UI to show error state
    const cpuSpan = document.getElementById('cpu');
    const ramSpan = document.getElementById('ram');
    const diskSpan = document.getElementById('disk');
    const netInSpan = document.getElementById('netIn');
    const netOutSpan = document.getElementById('netOut');
    const tsSpan = document.getElementById('ts');

    if(cpuSpan) cpuSpan.textContent = 'ERR';
    if(ramSpan) ramSpan.textContent = 'ERR';
    if(diskSpan) diskSpan.textContent = 'ERR';
    if(netInSpan) netInSpan.textContent = 'ERR';
    if(netOutSpan) netOutSpan.textContent = 'ERR';
    if(tsSpan) tsSpan.textContent = 'ERR';
  }
}

// --- Chart update functions (call drawChart directly now) ---
function pushCpu(v: number): void { pushValue(cpuHistory, v); }
function pushRam(v: number): void { pushValue(ramHistory, v); }
function pushDisk(v: number): void { pushValue(diskHistory, v); }

// --- Initialization ---
// Initial draw calls to set up canvas backgrounds and scale correctly
drawChart(cpuCtx, [], '#4ae3ff');
drawChart(ramCtx, [], '#ff4a4a');
drawChart(diskCtx, [], '#4aff4a');

// Fetch metrics initially and set interval for periodic updates
fetchMetrics(); // Initial fetch
setInterval(fetchMetrics, 2000); // Update every 2 seconds

export {}; // Ensures this file is treated as a module
