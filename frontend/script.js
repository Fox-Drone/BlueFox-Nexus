async function fetchMetrics(){
  try {
    const res = await fetch('http://0.0.0.0:3000/metrics');
    if(!res.ok) throw new Error('HTTP '+res.status);
    const data = await res.json();
    document.getElementById('cpu').textContent = data.cpu_usage.toFixed(2);
    document.getElementById('ram').textContent = data.ram_usage.toFixed(2);
    document.getElementById('disk').textContent = data.disk_usage.toFixed(2);
    document.getElementById('netIn').textContent = data.net_in;
    document.getElementById('netOut').textContent = data.net_out;
    document.getElementById('ts').textContent = new Date(data.timestamp * 1000).toLocaleString(); // Convert Unix timestamp to locale string

    // Push real data to history and draw charts
    pushCpu(data.cpu_usage);
    pushRam(data.ram_usage);
    pushDisk(data.disk_usage);

  } catch(e){ console.error(e); }
}

setInterval(fetchMetrics, 2000);
fetchMetrics();

// --- CPU Chart ---
let cpuHistory = [];
const cpuCanvas = document.getElementById('cpuChart');
const cpuCtx = cpuCanvas.getContext('2d');
const MAX_HISTORY = 60; // Keep last 60 samples
const CHART_WIDTH = cpuCanvas.width;
const CHART_HEIGHT = cpuCanvas.height;
const STEP_CPU = Math.max(1, CHART_WIDTH / (MAX_HISTORY - 1));

function drawChart(ctx, history, color){
  ctx.clearRect(0,0,CHART_WIDTH,CHART_HEIGHT);
  // background
  ctx.fillStyle = '#0b1220'; ctx.fillRect(0,0,CHART_WIDTH,CHART_HEIGHT);
  // line
  if(history.length > 1){
    ctx.lineWidth = 2; ctx.strokeStyle = color;
    ctx.beginPath();
    history.forEach((v,i)=>{
      const x = i * STEP_CPU;
      // Invert y-axis for chart (higher value is lower on canvas)
      const y = CHART_HEIGHT - (v / 100) * CHART_HEIGHT;
      if(i === 0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
    });
    ctx.stroke();
  }
}

function pushValue(history, value){
  history.push(value);
  if(history.length > MAX_HISTORY) history.shift(); // Remove oldest value
}

function pushCpu(v){ pushValue(cpuHistory, v); drawChart(cpuCtx, cpuHistory, '#4ae3ff'); }

// --- RAM Chart ---
let ramHistory = [];
const ramCanvas = document.getElementById('ramChart');
const ramCtx = ramCanvas.getContext('2d');
const STEP_RAM = Math.max(1, CHART_WIDTH / (MAX_HISTORY - 1));

function pushRam(v){ pushValue(ramHistory, v); drawChart(ramCtx, ramHistory, '#ff4a4a'); } // Red color for RAM

// --- Disk Chart ---
let diskHistory = [];
const diskCanvas = document.getElementById('diskChart');
const diskCtx = diskCanvas.getContext('2d');
const STEP_DISK = Math.max(1, CHART_WIDTH / (MAX_HISTORY - 1));

function pushDisk(v){ pushValue(diskHistory, v); drawChart(diskCtx, diskHistory, '#4aff4a'); } // Green color for Disk

// Initial draw calls to set up canvas backgrounds
drawChart(cpuCtx, [], '#4ae3ff');
drawChart(ramCtx, [], '#ff4a4a');
drawChart(diskCtx, [], '#4aff4a');


export{};
