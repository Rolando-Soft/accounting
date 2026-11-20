class ReportsController < ApplicationController
  def index
  end

  # One column per period end date, most recent first — @periods controls
  # how many (1, the plain single-date view, up to 3).
  def balance_sheet
    @as_of = parse_date(params[:as_of]) || Date.current
    @periods = (params[:periods].presence || "1").to_i.clamp(1, 3)
    @dates = period_end_dates(@as_of, @periods)
    @columns = @dates.map { |date| balance_sheet_column(date) }
  end

  def income_statement
    @start_date = parse_date(params[:start_date]) || Date.current.beginning_of_month
    @end_date = parse_date(params[:end_date]) || Date.current.end_of_month
    @accounts_by_type = balances_by_type(%w[income expense], from: @start_date, upto: @end_date)
    @total_income = @accounts_by_type["income"].sum { |_account, balance| balance }
    @total_expense = @accounts_by_type["expense"].sum { |_account, balance| balance }
    @net_income = @total_income - @total_expense
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

  def balance_sheet_column(as_of)
    accounts_by_type = balances_by_type(%w[asset liability equity], upto: as_of)
    total_assets = accounts_by_type["asset"].sum { |_account, balance| balance }
    total_liabilities = accounts_by_type["liability"].sum { |_account, balance| balance }

    # Income/expense accounts reset each period and aren't themselves part
    # of equity, but the balance sheet still needs their net effect on it —
    # otherwise assets would never equal liabilities + equity without an
    # explicit period-close step. "Current Earnings" is that net effect
    # (all income minus all expense since inception, through as_of), shown
    # as a computed equity line rather than a real account.
    income_and_expense = balances_by_type(%w[income expense], upto: as_of)
    current_earnings = income_and_expense["income"].sum { |_a, b| b } - income_and_expense["expense"].sum { |_a, b| b }
    total_equity = accounts_by_type["equity"].sum { |_account, balance| balance } + current_earnings

    {
      as_of: as_of,
      accounts_by_type: accounts_by_type,
      total_assets: total_assets,
      total_liabilities: total_liabilities,
      current_earnings: current_earnings,
      total_equity: total_equity
    }
  end

  # { "asset" => [[account, balance], ...], ... } for the given types, each
  # account's balance being signed_amount summed over entries whose
  # transaction date falls within [from, upto] (from is optional).
  def balances_by_type(types, upto:, from: nil)
    accounts = Account.where(account_type: types).includes(entries: :journal_transaction).order(:name)
    grouped = accounts.group_by(&:account_type)

    types.index_with do |type|
      (grouped[type] || []).map do |account|
        entries_in_range = account.entries.select do |entry|
          date = entry.journal_transaction.date
          date && date <= upto && (from.nil? || date >= from)
        end
        [account, entries_in_range.sum(&:signed_amount)]
      end
    end
  end
end
