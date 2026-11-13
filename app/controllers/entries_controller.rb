class EntriesController < ApplicationController
  before_action :set_entry, only: %i[update]

  REGISTER_ACCOUNT_TYPES = %w[asset liability].freeze
  VIEW_FILTERS = %w[this_month last_month last_3_months this_year last_year all_dates].freeze
  STATUSES = Entry.reconciliation_statuses.keys

  def index
    @accounts = Account.where(account_type: REGISTER_ACCOUNT_TYPES).order(:account_type, :name)
    @account = @accounts.find_by(id: params[:account_id]) || @accounts.first

    @view_filter = VIEW_FILTERS.include?(params[:view_filter]) ? params[:view_filter] : "this_month"
    @selected_statuses = Array(params[:statuses]).presence || STATUSES
    @balance_to_reconcile = params[:balance_to_reconcile].presence&.to_d || 0

    if @account
      all_entries = @account.entries.includes(journal_transaction: { entries: :account }).to_a
      entries_in_view = all_entries.select { |e| within_date_range?(e.journal_transaction.date, @view_filter) }

      @cleared_balance = sum_signed(entries_in_view.select { |e| e.cleared? || e.reconciled? })
      @uncleared_balance = sum_signed(entries_in_view.select(&:unreconciled?))
      @working_balance = sum_signed(all_entries)
      @pending_to_clear = @cleared_balance - @balance_to_reconcile

      @entries = entries_in_view
        .select { |e| @selected_statuses.include?(e.reconciliation_status) }
        .sort_by { |e| [ e.journal_transaction.date, e.id ] }
        .reverse
    else
      @cleared_balance = @uncleared_balance = @working_balance = @pending_to_clear = 0
      @entries = []
    end
  end

  def update
    return_to = params[:return_to].presence || entries_path
    if @entry.update(entry_params)
      redirect_to return_to, notice: "Entry updated."
    else
      redirect_to return_to, alert: @entry.errors.full_messages.to_sentence
    end
  end

  private

  def set_entry
    @entry = Entry.find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(:reconciliation_status)
  end

  def sum_signed(entries)
    entries.sum(&:signed_amount)
  end

  def within_date_range?(date, filter)
    today = Date.current
    case filter
    when "last_month"
      date.between?(today.prev_month.beginning_of_month, today.prev_month.end_of_month)
    when "last_3_months"
      date.between?(3.months.ago.to_date, today)
    when "this_year"
      date.between?(today.beginning_of_year, today.end_of_year)
    when "last_year"
      date.between?(today.prev_year.beginning_of_year, today.prev_year.end_of_year)
    when "all_dates"
      true
    else # "this_month"
      date.between?(today.beginning_of_month, today.end_of_month)
    end
  end
end
