import { Controller } from "@hotwired/stimulus"

// Fuzzy-matched payee suggestions below the Payee field, backed by
// JournalTransactionsController#payee_suggestions (reuses the same
// Levenshtein/substring matching as the transaction list's search box).
export default class extends Controller {
  static targets = ["input", "list"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }

  search() {
    clearTimeout(this.debounceTimer)
    const query = this.inputTarget.value.trim()

    if (!query) {
      this.hide()
      return
    }

    this.debounceTimer = setTimeout(() => this.fetchSuggestions(query), 200)
  }

  async fetchSuggestions(query) {
    const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok) return

    const payees = await response.json()
    this.render(payees)
  }

  render(payees) {
    if (payees.length === 0) {
      this.hide()
      return
    }

    this.listTarget.innerHTML = payees.map((payee) =>
      `<li class="px-3 py-2 hover:bg-blue-100 cursor-pointer" data-action="mousedown->payee-autocomplete#select">${this.escape(payee)}</li>`
    ).join("")
    this.listTarget.classList.remove("hidden")
  }

  select(event) {
    this.inputTarget.value = event.target.textContent
    this.hide()
  }

  // mousedown (not blur) fires first so a click can still register; this
  // just handles tabbing/clicking away from the field entirely.
  hide() {
    this.listTarget.classList.add("hidden")
    this.listTarget.innerHTML = ""
  }

  escape(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
