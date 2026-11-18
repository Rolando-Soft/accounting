import { Controller } from "@hotwired/stimulus"

// Makes an entire row clickable, navigating to a given URL — used so the
// register doesn't need a dedicated "Edit" column (saves space on mobile).
export default class extends Controller {
  static values = { url: String }

  visit() {
    Turbo.visit(this.urlValue)
  }

  // Attached to interactive elements inside the row (e.g. the status
  // toggle button) with the :stop modifier so their clicks don't also
  // trigger the row's own click action.
  ignore() {}
}
