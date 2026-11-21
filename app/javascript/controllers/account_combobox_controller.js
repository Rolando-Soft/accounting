import { Controller } from "@hotwired/stimulus"

// Turns a plain <select> of accounts into a fuzzy-searchable combobox:
// type to filter (substring or close Levenshtein match, same idea as the
// payee search), click/Enter to choose. The <select> itself stays in the
// DOM (hidden) and keeps driving real form submission and any existing
// onchange behavior — only how the user picks a value changes.
export default class extends Controller {
  static targets = ["select", "input", "list"]

  connect() {
    // The blank option (e.g. "All accounts", "None (top-level)") stays in
    // the list so there's a way back to it once something else is picked.
    this.options = Array.from(this.selectTarget.options)
      .map((option) => ({ value: option.value, label: option.text }))

    this.syncInputFromSelect()
    this.handleOutsideClick = (event) => {
      if (!this.element.contains(event.target)) this.hide()
    }
    document.addEventListener("click", this.handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  syncInputFromSelect() {
    const selected = this.selectTarget.options[this.selectTarget.selectedIndex]
    this.inputTarget.value = selected && selected.value ? selected.text : ""
  }

  open() {
    this.render(this.options)
  }

  search() {
    const query = this.inputTarget.value.trim()
    this.render(query ? this.options.filter((option) => this.fuzzyMatch(query, option.label)) : this.options)
  }

  selectTopMatch(event) {
    event.preventDefault()
    const first = this.listTarget.querySelector("li[data-value]")
    if (first) this.apply(first.dataset.value, first.textContent)
  }

  select(event) {
    this.apply(event.target.dataset.value, event.target.textContent)
  }

  apply(value, label) {
    const option = this.options.find((o) => o.value === value)
    if (!option) return

    this.selectTarget.value = option.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.inputTarget.value = label
    this.hide()
  }

  close() {
    this.hide()
    this.syncInputFromSelect()
  }

  render(options) {
    this.listTarget.innerHTML = options.length === 0
      ? `<li class="px-3 py-2 text-gray-500">No matches</li>`
      : options.map((option) =>
          `<li class="px-3 py-2 hover:bg-blue-100 cursor-pointer" data-value="${option.value}" data-action="mousedown->account-combobox#select">${this.escape(option.label)}</li>`
        ).join("")
    this.listTarget.classList.remove("hidden")
  }

  hide() {
    this.listTarget.classList.add("hidden")
  }

  // Substring match against the whole label, or a close match (typo
  // tolerant) against any individual word in it — a plain whole-label
  // Levenshtein comparison falls apart on multi-word labels like "Credit
  // Card" when the user has only typed part of one word.
  fuzzyMatch(query, label) {
    const q = query.toLowerCase()
    const l = label.toLowerCase()
    if (l.includes(q)) return true

    const maxDistance = q.length <= 4 ? 1 : q.length <= 8 ? 2 : 3
    return l.split(/\s+/).some((word) => word.startsWith(q) || this.levenshtein(q, word) <= maxDistance)
  }

  levenshtein(a, b) {
    const costs = []
    for (let i = 0; i <= b.length; i++) costs[i] = i
    for (let i = 1; i <= a.length; i++) {
      let previous = costs[0]
      costs[0] = i
      for (let j = 1; j <= b.length; j++) {
        const current = costs[j]
        costs[j] = a[i - 1] === b[j - 1] ? previous : Math.min(costs[j] + 1, costs[j - 1] + 1, previous + 1)
        previous = current
      }
    }
    return costs[b.length]
  }

  escape(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
