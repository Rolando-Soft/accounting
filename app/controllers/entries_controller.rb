class EntriesController < ApplicationController
  include DateRangeFilterable

  before_action :set_entry, only: %i[update]

  REGISTER_ACCOUNT_TYPES = %w[asset liability].freeze
  STATUSES = Entry.reconciliation_statuses.keys

  def index
    @return_to = request.fullpath
    load_register(params)
  end

  def update
    return_to = params[:return_to].presence || entries_path

    if @entry.update(entry_params)
      respond_to do |format|
        format.html { redirect_to return_to, notice: "Entry updated." }
        format.turbo_stream do
          @return_to = return_to
          load_register(context_params_from(return_to))
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to return_to, alert: @entry.errors.full_messages.to_sentence }
        format.turbo_stream do
          @return_to = return_to
          render turbo_stream: turbo_stream.replace(dom_id(@entry), partial: "entries/entry_row", locals: { entry: @entry })
        end
      end
    end
  end

  # Finalizes every ticked (cleared) entry in the current view as
  # reconciled, but only once the statement difference is exactly zero —
  # the whole point of ticking entries off against a statement first.
  def reconcile
    return_to = params[:return_to].presence || entries_path
    load_register(params)

    if @account && @difference.round(2).zero?
      count = @ticked_entries.size
      @ticked_entries.each { |entry| entry.update!(reconciliation_status: :reconciled) }
      redirect_to return_to, notice: "Reconciled #{count} #{"entry".pluralize(count)}."
    else
      redirect_to return_to, alert: "Difference must be $0.00 before you can reconcile."
    end
  end

  private

  def set_entry
    @entry = Entry.find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(:reconciliation_status)
  end

  # Rebuilds the register's full context (account, filters, balances,
  # visible entries) from a params-like hash, so index and the
  # turbo_stream branch of update share one source of truth.
  def load_register(source_params)
    @accounts = Account.where(account_type: REGISTER_ACCOUNT_TYPES).postable.ordered_by_type
    @account = @accounts.find_by(id: source_params[:account_id]) || @accounts.first

    @view_filter = normalize_view_filter(source_params[:view_filter])
    @selected_statuses = Array(source_params[:statuses]).presence || STATUSES
    @statement_balance = source_params[:statement_balance].presence&.delete(",")&.to_d || 0
    @projects = Project.order(:name)
    @project = @projects.find_by(id: source_params[:project_id])

    if @account
      all_entries = @account.entries.includes(journal_transaction: { entries: :account }).to_a
      entries_in_view = all_entries.select { |e| within_date_range?(e.journal_transaction.date, @view_filter) }

      # Reconciled: finalized against a past statement. Ticked: matched
      # against the current statement but not yet finalized. Computed is
      # their sum; Difference is how far Computed is from the statement's
      # own ending balance (drives toward $0 as you finish reconciling).
      # These always reflect the real, unfiltered account — like the
      # status checkboxes below, the Project filter only narrows which
      # rows are *listed*, so it never throws off reconciling against a
      # real bank/card statement.
      @ticked_entries = entries_in_view.select(&:cleared?)
      @reconciled_balance = sum_signed(entries_in_view.select(&:reconciled?))
      @ticked_balance = sum_signed(@ticked_entries)
      @computed_balance = @reconciled_balance + @ticked_balance
      @difference = @statement_balance - @computed_balance
      @working_balance = sum_signed(all_entries)

      @entries = entries_in_view
        .select { |e| @selected_statuses.include?(e.reconciliation_status) }
        .select { |e| @project.nil? || e.project_id == @project.id }
        .sort_by { |e| [ e.journal_transaction.date, e.id ] }
        .reverse
    else
      @reconciled_balance = @ticked_balance = @computed_balance = @difference = @working_balance = 0
      @entries = []
      @ticked_entries = []
    end
  end

  # The register's filters (account, view filter, statuses, balance to
  # reconcile) travel as the query string of `return_to`, so we recover
  # them from there instead of resubmitting them on every status toggle.
  def context_params_from(return_to)
    Rack::Utils.parse_nested_query(URI.parse(return_to).query).with_indifferent_access
  rescue URI::InvalidURIError
    {}
  end

  def sum_signed(entries)
    entries.sum(&:signed_amount)
  end
end
