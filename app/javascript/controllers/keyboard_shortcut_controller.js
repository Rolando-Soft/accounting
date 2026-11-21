import { Controller } from "@hotwired/stimulus"

// Navigates to a URL when a bare key is pressed — used for page-level
// "jump to" shortcuts (e.g. "n" for New account). Modifier combos like
// Ctrl/Cmd+N are reserved by the browser itself (new window) and never
// reach page JS, so shortcuts here are always a single unmodified key,
// ignored while the user is typing in a field.
export default class extends Controller {
  static values = { key: String, url: String }

  connect() {
    this.handleKeydown = (event) => {
      if (event.metaKey || event.ctrlKey || event.altKey) return

      const target = event.target
      if (target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable) return

      if (event.key.toLowerCase() === this.keyValue.toLowerCase()) {
        event.preventDefault()
        Turbo.visit(this.urlValue)
      }
    }
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }
}
