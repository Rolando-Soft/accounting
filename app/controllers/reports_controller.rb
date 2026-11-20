class ReportsController < ApplicationController
  def index
  end

  # One column per period end date, most recent first — @periods controls
  # how many (1, the plain single-date view, up to 3).
  def balance_sheet
    @as_of = parse_date(params[:as_of]) || Date.current
    @periods = (params[:periods].presence || "1").to_i.clamp(1, 3)
    @show_children = params[:show_children] != "0"
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
    @ranges = period_ranges(@end_date, @periods)
    @trees = account_trees(%w[income expense])
    @columns = @ranges.map { |from, to| income_statement_column(from, to) }
  end

  private

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
    accounts = Account.where(account_type: types).includes(entries: :journal_transaction)

    accounts.index_with do |account|
      account.entries.select do |entry|
        date = entry.journal_transaction.date
        date && date <= upto && (from.nil? || date >= from)
      end.sum(&:signed_amount)
    end.transform_keys(&:id)
  end
end
