import { Controller } from "@hotwired/stimulus"

// Drives the journal transaction form: keeps the DB/CR totals live, and —
// when a "locked" entry row exists for the account the transaction was
// opened from (see JournalTransactionsController#register_account_id) —
// auto-computes that row's amount as whatever balances the other rows,
// so the user only ever fills in the "other side" of a transaction.
export default class extends Controller {
  static targets = [
    "row", "debit", "credit", "lockedDebit", "lockedCredit",
    "totalDebit", "totalCredit", "submit", "container", "template"
  ]

  connect() {
    this.recompute()
  }

  recompute() {
    let otherDebit = 0
    let otherCredit = 0
    this.debitTargets.forEach((input) => { if (this.rowVisible(input)) otherDebit += this.num(input.value) })
    this.creditTargets.forEach((input) => { if (this.rowVisible(input)) otherCredit += this.num(input.value) })

    const diff = otherDebit - otherCredit
    let lockedDebit = 0
    let lockedCredit = 0

    if (this.hasLockedDebitTarget && this.hasLockedCreditTarget) {
      if (diff > 0) {
        lockedCredit = diff
        this.lockedCreditTarget.value = diff.toFixed(2)
        this.lockedDebitTarget.value = ""
      } else if (diff < 0) {
        lockedDebit = -diff
        this.lockedDebitTarget.value = lockedDebit.toFixed(2)
        this.lockedCreditTarget.value = ""
      } else {
        this.lockedDebitTarget.value = ""
        this.lockedCreditTarget.value = ""
      }
    }

    const totalDebit = otherDebit + lockedDebit
    const totalCredit = otherCredit + lockedCredit

    if (this.hasTotalDebitTarget) this.totalDebitTarget.textContent = this.formatAmount(totalDebit)
    if (this.hasTotalCreditTarget) this.totalCreditTarget.textContent = this.formatAmount(totalCredit)

    if (this.hasSubmitTarget) {
      const balanced = totalDebit > 0 && Math.abs(totalDebit - totalCredit) < 0.005
      this.submitTarget.disabled = !balanced
    }
  }

  add(event) {
    event.preventDefault()
    const newIndex = new Date().getTime()
    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, newIndex)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
    this.recompute()
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest('[data-journal-form-target="row"]')
    const destroyField = row.querySelector('input[name$="[_destroy]"]')
    if (destroyField) {
      destroyField.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
    this.recompute()
  }

  rowVisible(input) {
    const row = input.closest('[data-journal-form-target="row"]')
    return !row || row.style.display !== "none"
  }

  num(value) {
    const parsed = parseFloat(value)
    return Number.isFinite(parsed) ? parsed : 0
  }

  formatAmount(amount) {
    return amount.toFixed(2)
  }
}
