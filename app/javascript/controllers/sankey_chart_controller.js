import { Controller } from "@hotwired/stimulus"
import { Chart, Tooltip } from "chart.js"
import { SankeyController, Flow, NodeElement } from "chartjs-chart-sankey"

Chart.register(SankeyController, Flow, NodeElement, Tooltip)

// Dataviz skill palette.md: green for inflows, blue for outflows, red for
// a shortfall — the only flow that runs money the "wrong" way.
const INCOME = "#1c5cab"
const EXPENSE = "#6da7ec"
const SAVINGS = "#2f9e44"
const SHORTFALL = "#c92a2a"
const NEUTRAL = "#9ca3af"

// The Cash Flow Diagram's three category nodes — flows into one of these
// (an account adding cash) get the same "cash increased" green as flows
// into Ending Cash, rather than falling through to the generic blue.
const CASH_CATEGORIES = ["Operating", "Investing", "Financing"]

export default class extends Controller {
  static targets = ["canvas"]
  static values = { flows: Array }

  connect() {
    // flow arrives as a JSON string (BigDecimal serializes that way to
    // avoid precision loss), so it must be coerced before Chart.js sums it.
    const data = this.flowsValue.map((flow) => ({ ...flow, flow: Number(flow.flow) }))

    this.chart = new Chart(this.canvasTarget, {
      type: "sankey",
      data: {
        datasets: [{
          data,
          colorFrom: (ctx) => this.colorFor(ctx.raw),
          colorTo: (ctx) => this.colorFor(ctx.raw),
          colorMode: "from",
          borderColor: "#ffffff",
          borderWidth: 1,
          labels: {
            color: "#374151"
          }
        }]
      },
      options: {
        maintainAspectRatio: false,
        plugins: {
          tooltip: {
            callbacks: {
              label: (item) => `${item.raw.from} → ${item.raw.to}: ${this.formatCurrency(item.raw.flow)}`
            }
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }

  colorFor(raw) {
    if (raw.from === "Shortfall") return SHORTFALL
    if (raw.from === "Beginning Cash" && raw.to === "Ending Cash") return NEUTRAL
    if (raw.from === "Beginning Cash") return EXPENSE
    if (raw.to === "Ending Cash" || raw.to === "Net Savings") return SAVINGS
    // A category funding another category's deficit (or its own expense
    // accounts) is cash being drawn down, same as Beginning Cash doing so.
    if (CASH_CATEGORIES.includes(raw.from)) return EXPENSE
    if (CASH_CATEGORIES.includes(raw.to)) return SAVINGS
    if (raw.to === "Income") return INCOME
    return EXPENSE
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(value || 0)
  }
}
