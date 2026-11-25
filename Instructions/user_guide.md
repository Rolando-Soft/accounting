# Account App — User Guide

Account App is a personal double-entry accounting application. Every transaction you record moves money between two or more accounts, with debits and credits always balancing — the same discipline professional bookkeeping systems use, made simple enough for every day use.

This guide walks through every screen and workflow currently in the app: getting signed in, setting up your accounts, recording transactions, reconciling your bank register, running reports, and working with multiple workspaces.

---

## 1. Getting started

### 1.1 First-time setup

The very first time you open the app on a fresh install, nobody has an account yet. You'll automatically land on a **Setup** page instead of a sign-in form. Enter:

- **Email address**
- **Password** and **Password confirmation**

Submitting this form creates your one administrator account and signs you in immediately. Once that first account exists, the setup page is permanently retired — anyone visiting it afterward is redirected straight to the sign-in page instead, so no one else can create an additional account through the wizard.

### 1.2 Signing in

After setup, every visit starts at the **Sign in** page: enter your email address and password and submit. If you forget your password, use the "forgot password" link on the sign-in page to request a reset email.
TODO: Setup email server in Rails

### 1.3 The navigation bar

Once signed in, a dark navigation bar runs across the top of every page with five links:

| Link | Takes you to |
|---|---|
| **Entries** | The bank/credit-card register and reconciliation |
| **Accounts** | Your chart of accounts |
| **Journal Transactions** | A flat list of every transaction, with its own entry form |
| **Reports** | Balance sheet, income statement, cash flow, and more |
| **Workspaces** | Switching between, and managing, separate sets of books |

On the far right of the bar is the **active workspace switcher** (see §6) — it always shows which set of books you're currently working in.

---

## 2. Accounts

Your **chart of accounts** is the backbone of the system. Every transaction posts to two or more accounts, so before entering transactions you need accounts set up for everything you plan to track: your bank accounts, credit cards, income sources, expense categories, and your equity.

### 2.1 The five account types

Every account belongs to exactly one type:

- **Asset** — things you own (checking account, cash, receivables)
- **Liability** — things you owe (credit cards, loans payable)
- **Income** — money coming in (salary, sales, interest earned)
- **Expense** — money going out (groceries, rent, utilities)
- **Equity** — your net worth / owner's stake in the books

### 2.2 Viewing accounts

The **Accounts** page lists every account, grouped under its type and indented by parent/child hierarchy. At the top you'll find:

- A **type filter** — checkboxes for each of the five types, so you can show or hide entire categories. An **All/None** toggle next to the checkboxes flips every box on or off in one click. Your filter choices are remembered the next time you visit the page.
- A **search box** — type any part of an account's name (typos are tolerated) to jump straight to matching accounts, regardless of where they sit in the hierarchy. Click **Clear** to return to the normal tree view.

Press **n** anywhere on this page as a shortcut to jump straight to the "new account" form.

### 2.3 Creating and editing an account

Click **New account** (or press **n**) to open the account form. Fill in:

- **Name** — must be unique within the workspace (the cursor starts here automatically)
- **Account type** — one of the five types above
- **Description** — optional free text
- **Cash flow category** — *required*. For an **Asset** account, choose **Cash** if the account *is* cash itself (checking, savings, petty cash) — otherwise choose **Operating**, **Investing**, or **Financing** for a non-cash asset (an investment like an ETF, a receivable, equipment), so its own effect shows up correctly on the Cash Flow Statement and Cash Flow Diagram instead of being treated as just another cash account that cancels out. Every other account type always picks Operating, Investing, or Financing. Hover the "?" next to the label for examples of what belongs in each category (e.g. receivables and payables are Operating; equipment and investments are Investing; loans and stock are Financing).
- **Parent account** — optional. Use this to build a hierarchy, e.g. a "Utilities" parent with "Electric" and "Water" children. A parent must be the same account type as its children, and **only "leaf" accounts (ones with no children) can actually hold transactions** — once an account has a child, it's automatically dropped from every account-picker dropdown used for posting transactions (the register and the journal-entry form), since transactions can only post to the leaf accounts underneath it.

Editing an account reuses the same form — click any account row to open it.

### 2.4 The equity account

Every double-entry ledger needs at least one **Equity** account representing your net worth or owner's capital — create one (e.g. "Owner's Equity" or "Opening Balance Equity") the same way as any other account, choosing **Equity** as the type. You'll typically post your opening balances against it when you first set up each asset and liability account (see §8).

### 2.5 Deleting an account

Click the **x** next to an account to delete it. An account can only be deleted if it has no transactions posted to it and no child accounts — otherwise the app will refuse and explain why.

---

## 3. Entering transactions

There are two ways to record a transaction: from the **register** (Entries) when you're reconciling a specific bank or credit card account, or from the standalone **Journal Transactions** screen when you just want to log something quickly. Both open the same entry form.

### 3.1 The Journal Transaction form

Whichever way you open it, the form asks for:

- **Date**
- **Payee** — free text, with autocomplete suggestions drawn from payees you've used before
- **Description**
- **Entries** — at least two rows, each with:
  - **Account** — searchable dropdown (type to filter)
  - **Description** — optional, specific to this entry
  - **DB** / **CR** — enter an amount in exactly one of these two columns per row. Whichever column you fill in sets whether that entry is a debit or a credit.
  - **R** — check this box to mark the entry reconciled directly from the form (see §4)

Click **Entry add** to add another row (for a transaction touching more than two accounts), or the **x** on a row to remove it.

**The transaction must balance**: total debits must equal total credits before it can be saved. The running totals at the bottom of the entry grid update live as you type, and the **Submit Journal Entry** button stays disabled until they match.

### 3.2 Starting from the register

On the **Entries** page, once you've selected an account, click **New transaction** (or press **n**) to open the form with that account's row already filled in and locked — you only need to fill in the other side(s) of the transaction.

### 3.3 Starting from Journal Transactions

The **Journal Transactions** page lists every transaction across all accounts, most recent first, with a search box (matches payees, typo-tolerant) and the same date **View Filter** described in §4.2. Click **New Journal Transaction** here when a transaction isn't tied to any one register account you're actively reconciling — for example, recording depreciation, or an equity opening balance.

Click any row to edit that transaction, or **Delete transaction** on the edit form to remove it entirely.

### 3.4 Editing a reconciled transaction

If a transaction includes an entry that's already been **reconciled** (finalized against a bank statement — see §4), the form shows a warning banner. Saving a change or deleting the transaction will prompt you to confirm, since it affects a balance you've already locked in through reconciliation.

---

## 4. The register and reconciliation

The **Entries** page is your check-register / bank-statement view: a running ledger for one asset or liability account at a time, with the tools to reconcile it against a real bank or credit-card statement.

### 4.1 Choosing an account

Use the account dropdown at the top to pick which register you're viewing. Only postable asset and liability accounts appear here.

### 4.2 Filtering what you see

- **View Filter** — This month, Last month, Last 3 months, This year, Last year, or All dates.
- **Status checkboxes** — Unreconciled, Cleared, Reconciled. Uncheck any status to hide those entries from the list.

### 4.3 The balance tiles

Above the entry table, five figures update live:

| Tile | Meaning |
|---|---|
| **Reconciled** | Total of entries already finalized against a past statement |
| **Ticked** | Total of entries you've matched to the *current* statement but not yet finalized |
| **Computed** | Reconciled + Ticked — what your statement balance *should* equal once you're done |
| **Statement** | An editable field — type in the ending balance from your actual bank/card statement |
| **Difference** | Statement − Computed. This must hit **$0.00** before you can reconcile |
| **Working Balance** | The true running balance of every entry in view, reconciled or not |

### 4.4 Ticking off entries

Each entry row ends in a small checkbox-style button in the **Status** column:

- Click it once to mark an entry **Cleared** (ticked off against your statement) — a filled dot appears.
- Click again to return it to **Unreconciled**.
- A **Reconciled** entry shows a locked checkmark and can't be toggled from the register directly — reconciled entries can only be un-reconciled by editing the transaction itself (see §3.4).

Work through your paper or online statement, ticking off every matching entry, until **Difference** reads **$0.00**.

### 4.5 Reconciling

Once the Difference is exactly zero, the **Reconcile** button becomes active. Click it (you'll be asked to confirm) to finalize every currently-ticked entry in view as **Reconciled**. This locks them in — reconciled entries are protected against accidental edits or deletion going forward.

---

## 5. Reports

The **Reports** page is a directory of every report, grouped by category:

**Financial Position**
- **Balance Sheet** — Assets, Liabilities, and Equity as of a chosen date. Supports showing 1–3 comparison periods side by side (each a prior month-end), toggling child-account detail on/off, and hiding zero-balance rows. Includes a computed "Current Earnings" equity line — your accumulated income minus expense to date — so Assets always equal Liabilities + Equity without a manual period-close step.

**Income & Spending**
- **Income Statement** — Income and Expense totals and Net Income for a chosen month, with 1–3 month comparison columns, child-account toggle, and zero-balance hiding, same as the Balance Sheet.
- **Expense Treemap** — a visual map of leaf expense accounts, sized by total activity in your chosen date range, for spotting at a glance where money is concentrated.
- **Income/Expense Comparison** — a bar chart of one income or expense account type's totals over time, bucketed by year, quarter, month, week, or day, for spotting trends.

**Cash Flow**
- **Cash Flow Statement** — your net change in cash for a chosen month (with 1–3 month comparisons), broken into Operating, Investing, and Financing activity based on each account's **Cash flow category** (set when you created the account — see §2.3). "Cash" here means your Asset accounts categorized **Cash**; a non-cash asset (an investment, say) shows its own effect under its own category instead.
- **Cash Flow Diagram** — the Cash Flow Statement's own numbers for a single month, as a Sankey diagram instead of a table: each account flows into or out of its Operating/Investing/Financing category, a category with a surplus flows into whichever category ran a deficit that month (or into Ending Cash once every deficit is covered), and your existing cash balance covers a deficit first whenever there's enough of it. The total reaching "Ending Cash" always matches the statement's own ending balance exactly.
- **Funds Flow Diagram** — a Sankey diagram for your chosen date range showing where money came from and where it went: each income account flows into a central "Income" node, which fans out to every expense account it funded. Whatever's left over flows to a green "Net Savings" band; if expenses outran income instead, a red "Shortfall" band flows in to make up the difference. Hover any band for its exact amount.

**Ledgers & Detail**
- **Account Ledger** — pick any account and see every entry ever posted to it, oldest first, with a running balance — useful for drilling into any line from the other reports.

All reports respect your currently active workspace (§6) — they never mix data across workspaces.

---

## 6. Workspaces

A **workspace** is a complete, separate set of books — its own chart of accounts and its own transactions, entirely isolated from any other workspace. Use separate workspaces for genuinely separate sets of finances (e.g. personal vs. a side business) that should never mix.

### 6.1 Switching workspaces

The workspace name in the top-right of the navigation bar is always the **active** workspace. Click it to open a dropdown listing every workspace; click any name to switch — every page (accounts, entries, reports) immediately reflects the newly active workspace.

You can also switch from the **Workspaces** page itself via the **Switch to** link on any non-active row.

### 6.2 Managing workspaces

The **Workspaces** page lists every workspace with its account and transaction counts:

- **New workspace** — just needs a unique name.
- **Edit** — rename a workspace.
- **Delete** — opens a confirmation page listing exactly what will be destroyed (every account, every transaction, in that workspace). You must type the workspace's name exactly to enable the delete button — this is permanent and cannot be undone. The very last remaining workspace can never be deleted; at least one must always exist.

---

## 7. Keyboard shortcuts

A couple of screens support a single-key shortcut for speed (not Ctrl/Cmd+N, since browsers reserve that combination for opening a new window):

- **Accounts index** — press **n** to jump to the new-account form.
- **Entries (register)** — press **n** to jump to a new transaction, pre-filled with the account you're currently viewing.

---

## 8. Quick-start checklist

For a brand-new set of books:

1. Complete the one-time **Setup** wizard to create your login (§1.1).
2. Create an **Equity** account (§2.4) — you'll use it to post opening balances.
3. Create your **Asset** accounts (checking, savings, cash) and **Liability** accounts (credit cards, loans), each with a **Cash flow category**.
4. Create the **Income** and **Expense** categories you expect to use regularly.
5. Post an opening-balance transaction for each account against your Equity account, so your books start with accurate balances.
6. From then on, record transactions as they happen — either from the **Entries** register (best when reconciling against a statement) or from **Journal Transactions** (best for anything not tied to a bank/card statement).
7. Reconcile each asset/liability account against its statement periodically (§4).
8. Check **Reports** any time for a snapshot of where you stand.
