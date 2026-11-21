import { Controller } from "@hotwired/stimulus"
import { Chart, BarController, BarElement, CategoryScale, LinearScale, Tooltip } from "chart.js"

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip)

// Sequential blue (dataviz skill palette.md) — a single series needs no
// legend, so one hue is enough; the title/subtitle says what's plotted.
const BLUE = "#2a78d6"
const GRIDLINE = "#e1e0d9"

export default class extends Controller {
  static targets = ["canvas"]
  static values = { bars: Array }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels: this.barsValue.map((bar) => bar.label),
        datasets: [{
          data: this.barsValue.map((bar) => Number(bar.value)),
          backgroundColor: BLUE,
          borderRadius: 4,
          maxBarThickness: 24
        }]
      },
      options: {
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true, grid: { color: GRIDLINE }, ticks: { color: "#898781" } },
          x: { grid: { display: false }, ticks: { color: "#898781" } }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (item) => this.formatCurrency(item.parsed.y)
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(value || 0)
  }
}
