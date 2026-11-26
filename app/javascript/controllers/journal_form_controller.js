import { Controller } from "@hotwired/stimulus"

// Drives the journal transaction form: keeps the DB/CR totals live, and —
// when a "locked" entry row exists for the account the transaction was
// opened from (see JournalTransactionsController#register_account_id) —
// auto-computes that row's amount as whatever balances the other rows,
// so the user only ever fills in the "other side" of a transaction.
export default class extends Controller {
  static targets = [
    "row", "debit", "credit", "lockedDebit", "lockedCredit",
    "totalDebit", "totalCredit", "submit", "container", "template",
    "projectHeader", "projectLine"
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
        this.lockedCreditTarget.value = this.formatAmount(diff)
        this.lockedDebitTarget.value = ""
      } else if (diff < 0) {
        lockedDebit = -diff
        this.lockedDebitTarget.value = this.formatAmount(lockedDebit)
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

    // A newly added line starts out tagged with whatever project is
    // currently selected at the header, same as every existing line.
    if (this.hasProjectHeaderTarget && this.projectHeaderTarget.value) {
      const newRow = this.rowTargets[this.rowTargets.length - 1]
      const projectSelect = newRow?.querySelector('[data-journal-form-target~="projectLine"]')
      if (projectSelect) projectSelect.value = this.projectHeaderTarget.value
    }

    this.recompute()
  }

  // The header Project selector is a convenience, not a form field of its
  // own — it just stamps its value onto every line's own project select,
  // which stays independently editable afterward (a per-line override).
  applyProjectToAllLines() {
    const value = this.projectHeaderTarget.value
    this.projectLineTargets.forEach((select) => {
      if (this.rowVisible(select)) select.value = value
    })
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

  // Re-displays a DB/CR field as "1,500.00" once the user leaves it,
  // rather than live-masking every keystroke (which would fight cursor
  // position). Typing freely while focused, including digits with no
  // commas yet, is unaffected.
  reformat(event) {
    if (event.target.value.trim() === "") return
    event.target.value = this.formatAmount(this.num(event.target.value))
  }

  // Comma thousands separators are a display convenience only — strip
  // them before parsing, since "1,500".parseFloat would otherwise stop at
  // the comma and silently read as 1.
  num(value) {
    const parsed = parseFloat(String(value).replace(/,/g, ""))
    return Number.isFinite(parsed) ? parsed : 0
  }

  formatAmount(amount) {
    return amount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
