class JournalTransactionsController < ApplicationController
  def index
    @return_to = request.fullpath
    @journal_transactions = JournalTransaction.includes(entries: :account).search_by_payee(params[:q])
      .sort_by { |jt| [jt.date, jt.id] }.reverse
  end

  def new
    @journal_transaction = JournalTransaction.new(date: Date.current)
    @register_account_id = params[:register_account_id].presence&.to_i
    @return_to = params[:return_to].presence
    if @register_account_id
      @journal_transaction.entries.build(account_id: @register_account_id)
      @journal_transaction.entries.build
    else
      2.times { @journal_transaction.entries.build }
    end
  end

  def create
    @register_account_id = params[:register_account_id].presence&.to_i
    @return_to = params[:return_to].presence
    @journal_transaction = JournalTransaction.new(journal_transaction_params)
    if @journal_transaction.save
      redirect_to @return_to.presence || journal_transactions_path, notice: 'Journal transaction was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @journal_transaction = JournalTransaction.find(params[:id])
  end

  def edit
    @journal_transaction = JournalTransaction.find(params[:id])
    @register_account_id = params[:register_account_id].presence&.to_i
    @return_to = params[:return_to].presence
  end

  def update
    @journal_transaction = JournalTransaction.find(params[:id])
    @register_account_id = params[:register_account_id].presence&.to_i
    @return_to = params[:return_to].presence
    if @journal_transaction.update(journal_transaction_params)
      redirect_to @return_to.presence || journal_transactions_path, notice: 'Journal transaction was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @journal_transaction = JournalTransaction.find(params[:id])
    @journal_transaction.destroy
    redirect_to params[:return_to].presence || journal_transactions_path, notice: "Journal transaction deleted."
  end

  # Fuzzy-matched payee suggestions for the transaction form's autocomplete.
  def payee_suggestions
    payees = params[:q].present? ? JournalTransaction.search_by_payee(params[:q]).filter_map(&:payee).uniq.first(8) : []
    render json: payees
  end

  private
  def journal_transaction_params
    params.require(:journal_transaction).permit(:date, :description, :payee, :allow_reconciled_changes,
      entries_attributes: [:id, :account_id, :debit_amount, :credit_amount, :mark_reconciled, :description, :_destroy])
  end
end
