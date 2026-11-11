class JournalTransactionsController < ApplicationController
  def index
    @journal_transactions = JournalTransaction.all
  end

  def new
    @journal_transaction = JournalTransaction.new
    2.times { @journal_transaction.entries.build }
  end

  def create
    @journal_transaction = JournalTransaction.new(journal_transaction_params)
    if @journal_transaction.save
      redirect_to journal_transactions_path, notice: 'Journal transaction was successfully created.'
    else
      render :new
    end
  end

  def show
    @journal_transaction = JournalTransaction.find(params[:id])
  end

  def edit
    @journal_transaction = JournalTransaction.find(params[:id])
  end

  def update
    @journal_transaction = JournalTransaction.find(params[:id])
    if @journal_transaction.update(journal_transaction_params)
      redirect_to journal_transactions_path, notice: 'Journal transaction was successfully updated.'
    else
      render :edit
    end
  end

  private
  def journal_transaction_params
    params.require(:journal_transaction).permit(:date, :description, entries_attributes: [:id, :account_id, :amount, :entry_type, :_destroy])
  end
end
