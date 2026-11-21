import { Controller } from "@hotwired/stimulus"
import { Chart, LinearScale, Tooltip } from "chart.js"
import { TreemapController, TreemapElement } from "chartjs-chart-treemap"

Chart.register(TreemapController, TreemapElement, LinearScale, Tooltip)

// Sequential blue ramp, light -> dark (dataviz skill palette.md), one tile
// color per account sized by its relative share of the largest tile shown.
const RAMP = ["#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#2a78d6", "#1c5cab", "#104281"]
const LIGHT_STEPS = 3 // steps 0..LIGHT_STEPS-1 read better with dark text than white

export default class extends Controller {
  static targets = ["canvas"]
  static values = { tiles: Array }

  connect() {
    // tile.value arrives as a JSON string (BigDecimal serializes that way
    // to avoid precision loss), so it must be coerced before arithmetic.
    const max = Math.max(...this.tilesValue.map((tile) => Number(tile.value)), 1)
    const total = this.tilesValue.reduce((sum, tile) => sum + Number(tile.value), 0) || 1
    const rampIndex = (value) => Math.min(RAMP.length - 1, Math.floor(Math.min(value / max, 1) * (RAMP.length - 1)))

    this.chart = new Chart(this.canvasTarget, {
      type: "treemap",
      data: {
        datasets: [{
          data: this.tilesValue,
          key: "value",
          spacing: 0,
          borderWidth: 3,
          borderColor: "#ffffff",
          borderRadius: 6,
          backgroundColor: (ctx) => ctx.raw ? RAMP[rampIndex(ctx.raw.v)] : RAMP[0],
          labels: {
            display: true,
            overflow: "hidden",
            color: (ctx) => ctx.raw && rampIndex(ctx.raw.v) < LIGHT_STEPS ? "#0b0b0b" : "#ffffff",
            font: { size: 13 },
            formatter: (ctx) => [ctx.raw._data.name, this.formatPercentage(ctx.raw.v / total)]
          }
        }]
      },
      options: {
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: (items) => items[0]?.raw?.name || "",
              label: (item) => this.formatCurrency(item.raw?.value)
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

  formatPercentage(ratio) {
    return new Intl.NumberFormat("en-US", { style: "percent", maximumFractionDigits: 1 }).format(ratio || 0)
  }
}
