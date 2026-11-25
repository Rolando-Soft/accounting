import { Controller } from "@hotwired/stimulus"

// The "Cash" cash-flow category only means anything on an Asset account —
// hide that option from every other type's dropdown, deselecting it first
// if it was somehow already chosen, rather than let a non-asset account be
// marked as cash.
export default class extends Controller {
  static targets = ["accountType", "cashOption"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isAsset = this.accountTypeTarget.value === "asset"
    if (!isAsset && this.cashOptionTarget.selected) this.cashOptionTarget.selected = false
    this.cashOptionTarget.hidden = !isAsset
  }
}
