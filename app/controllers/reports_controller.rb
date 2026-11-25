class ReportsController < ApplicationController
  include DateRangeFilterable

  def index
  end

  # One column per period end date, most recent first — @periods controls
  # how many (1, the plain single-date view, up to 3).
  def balance_sheet
    @as_of = parse_date(params[:as_of]) || Date.current
    @periods = (params[:periods].presence || "1").to_i.clamp(1, 3)
    @show_children = params[:show_children] != "0"
    @hide_zero_balances = params[:hide_zero_balances] == "1"
    @dates = period_end_dates(@as_of, @periods)
    @trees = account_trees(%w[asset liability equity])
    @columns = @dates.map { |date| balance_sheet_column(date) }
  end

  # One column per calendar month, most recent first — @periods controls
  # how many (1, the plain single-month view, up to 3). The most recent
  # column runs from the start of @end_date's month through @end_date
  # itself (so the current, still-in-progress month reports to date);
  # earlier columns are each a full prior calendar month.
  def income_statement
    @end_date = parse_date(params[:end_date]) || Date.current
    @periods = (params[:periods].presence || "1").to_i.clamp(1, 3)
    @show_children = params[:show_children] != "0"
    @hide_zero_balances = params[:hide_zero_balances] == "1"
    @ranges = period_ranges(@end_date, @periods)
    @trees = account_trees(%w[income expense])
    @columns = @ranges.map { |from, to| income_statement_column(from, to) }
  end

  # Direct method: cash accounts are the asset accounts, and every other
  # account's entries are bucketed by its cash_flow_category. Because a
  # balanced transaction's debits and credits always net to zero, the
  # total across non-cash entries (negated) always equals cash's own
  # actual change — true regardless of how a transaction is split, with
  # no need to pair up entries. One column per calendar month, most
  # recent first, same as the Income Statement.
  def cash_flow_statement
    @end_date = parse_date(params[:end_date]) || Date.current
    @periods = (params[:periods].presence || "1").to_i.clamp(1, 3)
    @hide_zero_balances = params[:hide_zero_balances] == "1"
    @ranges = period_ranges(@end_date, @periods)
    @columns = @ranges.map { |from, to| cash_flow_column(from, to) }
  end

  CASH_FLOW_CATEGORY_LABELS = { "operating" => "Operating", "investing" => "Investing", "financing" => "Financing" }.freeze

  # The Cash Flow Statement's own numbers (cash_flow_column), reshaped into
  # a Sankey: Beginning Cash funds whichever categories drew cash down,
  # categories that added cash flow into Ending Cash, and each account's
  # own effect is shown flowing to/from its category — so this never
  # computes anything the statement doesn't already show, only redraws it.
  def cash_flow_diagram
    @end_date = parse_date(params[:end_date]) || Date.current
    from, to = period_ranges(@end_date, 1).first
    column = cash_flow_column(from, to)

    @flows = []

    CASH_FLOW_CATEGORY_LABELS.each do |category, label|
      column[:category_rows][category].each do |account, effect|
        next if effect.zero?
        if effect.positive?
          @flows << { from: account.name, to: label, flow: effect }
        else
          @flows << { from: label, to: account.name, flow: -effect }
        end
      end
    end

    @flows.concat(cash_reconciliation_flows(column))
  end

  # A single account's transaction history — every entry posted to it,
  # oldest first, with a running balance — so a Balance Sheet/Income
  # Statement line can be drilled into. Any account type is selectable
  # (unlike the bank-account-only register), since this isn't about
  # reconciling against a statement.
  def account_ledger
    @accounts = Account.ordered_by_type
    @account = @accounts.find_by(id: params[:account_id]) || @accounts.first
    @view_filter = normalize_view_filter(params[:view_filter])

    if @account
      from, to = view_filter_range(@view_filter)
      all_entries = @account.entries.includes(journal_transaction: { entries: :account }).to_a
        .sort_by { |entry| [entry.journal_transaction.date, entry.id] }

      @beginning_balance = from ? all_entries.select { |e| e.journal_transaction.date < from }.sum(&:signed_amount) : 0
      entries_in_range = all_entries.select { |e| from.nil? || e.journal_transaction.date.between?(from, to) }

      running_balance = @beginning_balance
      @rows = entries_in_range.map do |entry|
        running_balance += entry.signed_amount
        { entry: entry, running_balance: running_balance }
      end
      @ending_balance = running_balance
    else
      @beginning_balance = @ending_balance = 0
      @rows = []
    end
  end

  # A treemap of leaf expense accounts, each tile sized by its total
  # activity within the view filter's date range — a shape for spotting
  # where the money is concentrated that a table doesn't give you.
  def expense_treemap
    @view_filter = normalize_view_filter(params[:view_filter])
    from, to = view_filter_range(@view_filter)

    accounts = Account.where(account_type: "expense").postable.includes(entries: :journal_transaction)
    @tiles = accounts.filter_map do |account|
      total = account.entries.sum do |entry|
        date = entry.journal_transaction.date
        from.nil? || date.between?(from, to) ? entry.signed_amount : 0
      end
      { name: account.name, value: total } if total.positive?
    end.sort_by { |tile| -tile[:value] }
  end

  # Where money came from and where it went, as a Sankey diagram: each
  # income account flows into a central "Income" node, which flows out to
  # each expense account; the gap between total income and total expense
  # becomes a final "Net Savings" (or "Shortfall") flow, so the diagram
  # balances even though real income/expense never exactly match.
  def funds_flow_diagram
    @view_filter = normalize_view_filter(params[:view_filter])
    from, to = view_filter_range(@view_filter)

    income_by_account = balances_by_account(%w[income], upto: to || Date.current, from: from)
      .select { |_id, balance| balance.positive? }
    expense_by_account = balances_by_account(%w[expense], upto: to || Date.current, from: from)
      .select { |_id, balance| balance.positive? }

    total_income = income_by_account.values.sum
    total_expense = expense_by_account.values.sum

    @flows = []
    Account.where(id: income_by_account.keys).each do |account|
      @flows << { from: account.name, to: "Income", flow: income_by_account[account.id] }
    end
    Account.where(id: expense_by_account.keys).each do |account|
      @flows << { from: "Income", to: account.name, flow: expense_by_account[account.id] }
    end
    if total_income > total_expense
      @flows << { from: "Income", to: "Net Savings", flow: total_income - total_expense }
    elsif total_expense > total_income
      @flows << { from: "Shortfall", to: "Income", flow: total_expense - total_income }
    end
  end

  PERIODS = %w[yearly quarterly monthly weekly daily].freeze

  # One bar per period (year/quarter/month/week/day) of a single income or
  # expense account type's total activity — a trend view of the treemap's
  # totals, instead of a snapshot of where they're concentrated.
  def income_expense_comparison
    @account_type = %w[income expense].include?(params[:account_type]) ? params[:account_type] : "expense"
    @view_filter = normalize_view_filter(params[:view_filter])
    @period = PERIODS.include?(params[:period]) ? params[:period] : "monthly"
    from, to = view_filter_range(@view_filter)

    @accounts = Account.where(account_type: @account_type).postable.ordered_by_type
    @account = @accounts.find_by(id: params[:account_id])

    scoped_accounts = @account ? [@account] : @accounts.includes(entries: :journal_transaction)
    entries = scoped_accounts.flat_map(&:entries).select do |entry|
      date = entry.journal_transaction.date
      date && (from.nil? || date.between?(from, to))
    end

    @bars = entries.group_by { |entry| period_bucket(entry.journal_transaction.date, @period) }
      .sort_by { |(sort_key, _label), _group| sort_key }
      .map { |(_sort_key, label), group| { label: label, value: group.sum(&:signed_amount) } }
  end

  private

  # Flows that reconcile Beginning Cash to Ending Cash through each
  # category's net effect, without ever drawing a negative-amount flow (a
  # category in deficit instead *receives* from whichever surplus is
  # funding it, Beginning Cash's own balance first, then other categories
  # in Operating/Investing/Financing order).
  #
  # A Beginning Cash balance that started negative still has to be funded
  # from somewhere before anything is left over for Ending Cash, but
  # there's no account to draw that edge to — it's tracked as a "need"
  # with no label, so it silently consumes capacity instead of drawing a
  # flow, which is what keeps the diagram's Ending Cash total equal to the
  # statement's actual ending balance.
  def cash_reconciliation_flows(column)
    sources = []
    sources << ["Beginning Cash", column[:beginning_cash]] if column[:beginning_cash].positive?
    CASH_FLOW_CATEGORY_LABELS.each do |category, label|
      net = column[:category_totals][category]
      sources << [label, net] if net.positive?
    end

    needs = CASH_FLOW_CATEGORY_LABELS.filter_map do |category, label|
      net = column[:category_totals][category]
      [label, -net] if net.negative?
    end
    needs << [nil, -column[:beginning_cash]] if column[:beginning_cash].negative?

    flows = []
    needs.each do |need_label, amount|
      remaining = amount
      sources.each do |source|
        next if remaining <= 0 || source[1] <= 0
        drawn = [source[1], remaining].min
        flows << { from: source[0], to: need_label, flow: drawn } if need_label
        source[1] -= drawn
        remaining -= drawn
      end
    end

    sources.each do |label, capacity|
      flows << { from: label, to: "Ending Cash", flow: capacity } if capacity.positive?
    end
    flows
  end

  # [sort_key, label] for the period a date falls in, grouped so entries in
  # the same period collapse into the same bar and bars stay chronological.
  def period_bucket(date, period)
    case period
    when "yearly" then [date.year, date.year.to_s]
    when "quarterly"
      quarter = (date.month - 1) / 3 + 1
      [[date.year, quarter], "Q#{quarter} #{date.year}"]
    when "weekly"
      start = date.beginning_of_week
      [start, start.strftime("%b %-d, %Y")]
    when "daily"
      [date, date.strftime("%b %-d, %Y")]
    else
      [[date.year, date.month], date.strftime("%b %Y")]
    end
  end

  def parse_date(value)
    Date.parse(value) if value.present?
  rescue ArgumentError
    nil
  end

  # The most recent column is exactly as_of; each earlier one steps back a
  # full calendar month and lands on that month's last day, matching how a
  # comparative balance sheet normally lines up period end dates.
  def period_end_dates(as_of, periods)
    (0...periods).map { |i| i.zero? ? as_of : as_of.beginning_of_month - (i - 1).months - 1.day }
  end

  # [[from, to], ...] for each calendar month, most recent (possibly
  # partial, through end_date) first.
  def period_ranges(end_date, periods)
    (0...periods).map do |i|
      to = i.zero? ? end_date : end_date.beginning_of_month - (i - 1).months - 1.day
      [to.beginning_of_month, to]
    end
  end

  def income_statement_column(from, to)
    balances = balances_by_account(%w[income expense], from: from, upto: to)
    rollups = @trees.transform_values { |rows| rollup_balances(rows, balances) }
    total_income = @trees["income"].select { |row| row[:depth].zero? }.sum { |row| rollups["income"][row[:account].id] }
    total_expense = @trees["expense"].select { |row| row[:depth].zero? }.sum { |row| rollups["expense"][row[:account].id] }

    { from: from, to: to, balances: balances, rollups: rollups, total_income: total_income,
      total_expense: total_expense, net_income: total_income - total_expense }
  end

  def balance_sheet_column(as_of)
    balances = balances_by_account(%w[asset liability equity], upto: as_of)
    rollups = @trees.transform_values { |rows| rollup_balances(rows, balances) }
    total_assets = @trees["asset"].select { |row| row[:depth].zero? }.sum { |row| rollups["asset"][row[:account].id] }
    total_liabilities = @trees["liability"].select { |row| row[:depth].zero? }.sum { |row| rollups["liability"][row[:account].id] }

    # Income/expense accounts reset each period and aren't themselves part
    # of equity, but the balance sheet still needs their net effect on it —
    # otherwise assets would never equal liabilities + equity without an
    # explicit period-close step. "Current Earnings" is that net effect
    # (all income minus all expense since inception, through as_of), shown
    # as a computed equity line rather than a real account.
    income_and_expense_trees = account_trees(%w[income expense])
    income_and_expense = balances_by_account(%w[income expense], upto: as_of)
    income_and_expense_rollups = income_and_expense_trees.transform_values { |rows| rollup_balances(rows, income_and_expense) }
    total_income = income_and_expense_trees["income"].select { |row| row[:depth].zero? }
      .sum { |row| income_and_expense_rollups["income"][row[:account].id] }
    total_expense = income_and_expense_trees["expense"].select { |row| row[:depth].zero? }
      .sum { |row| income_and_expense_rollups["expense"][row[:account].id] }
    current_earnings = total_income - total_expense
    total_equity = @trees["equity"].select { |row| row[:depth].zero? }.sum { |row| rollups["equity"][row[:account].id] } + current_earnings

    { as_of: as_of, balances: balances, rollups: rollups, total_assets: total_assets,
      total_liabilities: total_liabilities, current_earnings: current_earnings, total_equity: total_equity }
  end

  # { "asset" => [{ account:, depth: }, ...], ... } — each type's accounts
  # in parent/child tree order (root accounts first, each one's children
  # immediately beneath it, alphabetically at every level), so views can
  # render them indented without worrying about hierarchy themselves.
  def account_trees(types)
    accounts = Account.where(account_type: types).to_a
    types.index_with { |type| flatten_tree(accounts.select { |a| a.account_type == type }, nil, 0) }
  end

  def flatten_tree(accounts, parent_id, depth)
    accounts.select { |a| a.parent_id == parent_id }.sort_by(&:name).flat_map do |account|
      [{ account: account, depth: depth }] + flatten_tree(accounts, account.id, depth + 1)
    end
  end

  # A parent account's displayed balance rolls up its own entries plus
  # every descendant's, so {type => {account_id => balance}} isn't enough
  # on its own — this adds the recursive total alongside it.
  def rollup_balances(tree_rows, own_balances)
    children_of = tree_rows.group_by { |row| row[:account].parent_id }
    totals = {}
    compute = lambda do |account|
      own_balances.fetch(account.id, 0) + children_of.fetch(account.id, []).sum { |row| compute.call(row[:account]) }
    end
    tree_rows.each { |row| totals[row[:account].id] = compute.call(row[:account]) }
    totals
  end

  # { account_id => balance } for the given types, each being signed_amount
  # summed over entries whose transaction date falls within [from, upto]
  # (from is optional) — the account's own entries only, no rollup.
  def balances_by_account(types, upto:, from: nil)
    balances_for_accounts(Account.where(account_type: types), upto: upto, from: from)
  end

  def balances_for_accounts(accounts, upto:, from: nil)
    accounts.includes(entries: :journal_transaction).index_with do |account|
      account.entries.select do |entry|
        date = entry.journal_transaction.date
        date && date <= upto && (from.nil? || date >= from)
      end.sum(&:signed_amount)
    end.transform_keys(&:id)
  end

  def cash_flow_column(from, to)
    category_rows = non_cash_category_balances(from: from, upto: to)
    category_totals = category_rows.transform_values { |rows| rows.sum { |_account, effect| effect } }
    net_change = category_totals.values.sum

    beginning_cash = balances_for_accounts(Account.cash, upto: from - 1.day).values.sum
    ending_cash = balances_for_accounts(Account.cash, upto: to).values.sum

    { from: from, to: to, category_rows: category_rows, category_totals: category_totals,
      net_change: net_change, beginning_cash: beginning_cash, ending_cash: ending_cash }
  end

  # { "operating" => [[account, cash_effect], ...], "investing" => [...],
  # "financing" => [...], "uncategorized" => [...] } for every non-cash
  # account (every non-asset account, plus any asset whose own
  # cash_flow_category isn't "cash", e.g. an investment) with entries in
  # [from, upto]. cash_effect is the entry's effect on cash — the negation
  # of its own debit-positive total, per the zero-sum identity above — not
  # the account's own normal-balance change (that's what signed_amount
  # gives, and it isn't equivalent once debit/credit and normal balance
  # disagree, e.g. paying down a liability).
  def non_cash_category_balances(upto:, from:)
    accounts = Account.non_cash.postable.includes(entries: :journal_transaction)
    grouped = accounts.group_by { |account| account.cash_flow_category || "uncategorized" }

    %w[operating investing financing uncategorized].index_with do |category|
      (grouped[category] || []).map do |account|
        raw_delta = account.entries.select do |entry|
          date = entry.journal_transaction.date
          date && date >= from && date <= upto
        end.sum { |entry| entry.debit? ? entry.amount : -entry.amount }

        [account, -raw_delta]
      end.sort_by { |account, _effect| [Account.account_types[account.account_type], account.name] }
    end
  end
end
