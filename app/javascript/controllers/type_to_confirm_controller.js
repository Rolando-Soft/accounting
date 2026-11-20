import { Controller } from "@hotwired/stimulus"

// Keeps a destructive submit button disabled until the typed text exactly
// matches a target value (e.g. the name of the thing being deleted).
// Server-side still re-checks the match itself — this only saves a trip.
export default class extends Controller {
  static targets = ["input", "submit"]
  static values = { match: String }

  connect() {
    this.check()
  }

  check() {
    this.submitTarget.disabled = this.inputTarget.value !== this.matchValue
  }
}
