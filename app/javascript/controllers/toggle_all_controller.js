import { Controller } from "@hotwired/stimulus"

// A single button that checks every checkbox in scope if any are
// unchecked, or unchecks them all if they're all already checked —
// then submits the form either way.
export default class extends Controller {
  static targets = ["checkbox"]

  toggle() {
    const allChecked = this.checkboxTargets.every((checkbox) => checkbox.checked)
    this.checkboxTargets.forEach((checkbox) => (checkbox.checked = !allChecked))
    this.element.closest("form").requestSubmit()
  }
}
