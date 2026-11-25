import { Controller } from "@hotwired/stimulus"

// A plain single-level dropdown: clicking the button toggles the menu,
// clicking anywhere outside collapses it back down. No hover — a gap
// between the button and an absolutely positioned menu breaks hover
// chains (the pointer crosses empty space the menu doesn't occupy,
// losing :hover and closing the menu before a click can land).
export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) this.menuTarget.classList.add("hidden")
  }
}
