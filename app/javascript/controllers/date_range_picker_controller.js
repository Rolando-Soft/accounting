import { Controller } from "@hotwired/stimulus"

// Shared date-range picker (Income Statement, Cash Flow Statement,
// Account Ledger, Project Profitability, Project Ledger): a click-to-
// toggle dropdown of presets, a Custom range with month+year fields, and
// ‹/› arrows that step the whole window by one month. Presets drive two
// hidden fields (range, shift); Custom drives two visible month inputs
// instead, each shifted by the arrows exactly like a preset's shift.
export default class extends Controller {
  static targets = ["menu", "rangeInput", "shiftInput", "customFields", "customStart", "customEnd"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.menuTarget.classList.add("hidden")
  }

  selectPreset(event) {
    const preset = event.params.preset
    this.rangeInputTarget.value = preset
    this.shiftInputTarget.value = "0"

    if (preset === "custom") {
      this.customFieldsTarget.classList.remove("hidden")
      return
    }

    this.customFieldsTarget.classList.add("hidden")
    this.element.closest("form").requestSubmit()
  }

  applyCustom() {
    this.rangeInputTarget.value = "custom"
    this.element.closest("form").requestSubmit()
  }

  cancelCustom() {
    this.customFieldsTarget.classList.add("hidden")
    this.menuTarget.classList.add("hidden")
  }

  shiftPrev() {
    this.shift(-1)
  }

  shiftNext() {
    this.shift(1)
  }

  shift(delta) {
    if (this.rangeInputTarget.value === "custom") {
      this.shiftMonthInput(this.customStartTarget, delta)
      this.shiftMonthInput(this.customEndTarget, delta)
    } else {
      this.shiftInputTarget.value = parseInt(this.shiftInputTarget.value || "0", 10) + delta
    }
    this.element.closest("form").requestSubmit()
  }

  // Month inputs submit "YYYY-MM" — walk that forward/back by a month
  // using a real Date so year boundaries carry correctly.
  shiftMonthInput(input, delta) {
    const [year, month] = input.value.split("-").map(Number)
    const date = new Date(year, month - 1 + delta, 1)
    input.value = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`
  }
}
