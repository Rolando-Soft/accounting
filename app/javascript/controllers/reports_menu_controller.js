import { Controller } from "@hotwired/stimulus"

// Click-to-toggle nav dropdown: clicking "Reports" opens the category
// list, clicking a category reveals its reports (only one open at a time,
// the active category highlighted), and clicking anywhere outside the
// whole thing collapses it back down. Click always works this way,
// everywhere (touch, keyboard, desktop) — on top of that, a device with a
// real mouse also gets hover-to-open as a shortcut, with a short
// close-delay so the pointer can travel from the category into its
// submenu without losing it; a touchscreen never sees this; it would
// otherwise get "stuck" hovering after a tap.
const HOVER_CAPABLE = window.matchMedia("(hover: hover) and (pointer: fine)").matches
const CLOSE_DELAY_MS = 150

export default class extends Controller {
  static targets = ["menu", "category", "submenu"]

  toggleMenu() {
    this.menuTarget.classList.toggle("hidden")
    if (this.menuTarget.classList.contains("hidden")) this.closeSubmenus()
  }

  toggleSubmenu(event) {
    const index = event.params.index
    const wasHidden = this.submenuTargets[index].classList.contains("hidden")
    this.closeSubmenus()
    if (wasHidden) this.openSubmenu(index)
  }

  openOnHover(event) {
    if (!HOVER_CAPABLE) return
    clearTimeout(this.closeTimeout)
    const index = event.params.index
    if (!this.submenuTargets[index].classList.contains("hidden")) return
    this.closeSubmenus()
    this.openSubmenu(index)
  }

  scheduleCloseOnHover() {
    if (!HOVER_CAPABLE) return
    clearTimeout(this.closeTimeout)
    this.closeTimeout = setTimeout(() => this.closeSubmenus(), CLOSE_DELAY_MS)
  }

  cancelScheduledClose() {
    if (!HOVER_CAPABLE) return
    clearTimeout(this.closeTimeout)
  }

  openSubmenu(index) {
    this.submenuTargets[index].classList.remove("hidden")
    this.categoryTargets[index].classList.add("bg-gray-100")
  }

  closeSubmenus() {
    this.submenuTargets.forEach((submenu) => submenu.classList.add("hidden"))
    this.categoryTargets.forEach((category) => category.classList.remove("bg-gray-100"))
  }

  closeIfOutside(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      this.closeSubmenus()
    }
  }
}
