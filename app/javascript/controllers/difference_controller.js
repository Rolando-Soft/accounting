import { Controller } from "@hotwired/stimulus"

// Recomputes "Difference" live as the user types a "Statement" ending
// balance, without a full page reload. Mirrors
// EntriesController#load_register (statement_balance - computed_balance).
// Computed Balance is read straight from its tile rather than cached, so
// it stays correct even after a Turbo Stream swap replaces that tile.
//
// Also keeps the Reconcile button in sync: it lives in a separate <form>
// (can't be nested inside the Statement field's form), so without this its
// enabled state and the value it would submit stay frozen at whatever they
// were on page load, even after the user types a new Statement amount.
//
// A row's status toggle re-renders Reconciled/Ticked/Computed/Difference via
// a Turbo Stream. The server only knows the Statement value from the last
// full page load, so its Difference figure is a best-effort fallback
// (correct with JS off) — a MutationObserver on the whole tile row notices
// the swap landing and reruns recompute() with the live, on-screen
// Statement value, which always wins once JS is available. A plain
// "turbo:submit-end" listener was tried first but isn't reliably ordered
// after the swap's DOM mutations, so don't reintroduce that approach.
export default class extends Controller {
  static targets = ["input", "output", "computed", "reconcileButton", "reconcileStatement"]

  connect() {
    this.observer = new MutationObserver(() => this.recompute())
    this.observer.observe(this.element, { childList: true, subtree: true, characterData: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  recompute() {
    // Mutating our own targets below would otherwise retrigger the observer.
    this.observer?.disconnect()

    const statementBalance = this.parseCurrency(this.inputTarget.value)
    const computedBalance = this.parseCurrency(this.computedTarget.textContent)
    const difference = statementBalance - computedBalance
    this.outputTarget.textContent = this.formatCurrency(difference)

    if (this.hasReconcileStatementTarget) {
      this.reconcileStatementTarget.value = this.inputTarget.value
    }

    if (this.hasReconcileButtonTarget) {
      const isZero = Math.abs(difference) < 0.005
      this.reconcileButtonTarget.disabled = !isZero
      this.reconcileButtonTarget.title = isZero
        ? "Finalize all ticked entries in this view as reconciled"
        : "Difference must be $0.00 before you can reconcile"
      this.reconcileButtonTarget.classList.toggle("bg-green-600", isZero)
      this.reconcileButtonTarget.classList.toggle("hover:bg-green-700", isZero)
      this.reconcileButtonTarget.classList.toggle("bg-gray-400", !isZero)
      this.reconcileButtonTarget.classList.toggle("cursor-not-allowed", !isZero)
    }

    this.observer?.observe(this.element, { childList: true, subtree: true, characterData: true })
  }

  // Reads a comma-formatted, $-prefixed, or plain number alike — strips
  // everything but digits/dot/minus before parsing.
  parseCurrency(text) {
    const value = parseFloat(text.replace(/[^0-9.-]/g, ""))
    return Number.isFinite(value) ? value : 0
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(amount)
  }

  // Re-displays the Statement field as "1,500.00" once the user leaves
  // it, same as a DB/CR field on the journal transaction form.
  reformatStatement() {
    if (this.inputTarget.value.trim() === "") return
    this.inputTarget.value = this.parseCurrency(this.inputTarget.value)
      .toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
