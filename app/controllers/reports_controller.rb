class ReportsController < ApplicationController
  def index
  end

  def balance_sheet
    @as_of = parse_date(params[:as_of]) || Date.current
    @accounts_by_type = balances_by_type(%w[asset liability equity], upto: @as_of)
    @total_assets = @accounts_by_type["asset"].sum { |_account, balance| balance }
    @total_liabilities = @accounts_by_type["liability"].sum { |_account, balance| balance }
    @total_equity = @accounts_by_type["equity"].sum { |_account, balance| balance }
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
