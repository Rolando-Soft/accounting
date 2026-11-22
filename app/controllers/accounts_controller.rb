class AccountsController < ApplicationController
  before_action :set_account, only: %i[ edit update destroy ]

  # GET /accounts or /accounts.json
  def index
    all_types = Account.account_types.keys
    if params[:account_types_submitted]
      @selected_types = all_types & Array(params[:account_types])
      @search = params[:q].to_s.strip
      session[:account_types_filter] = @selected_types
      session[:account_search] = @search
    else
      @selected_types = all_types & (session[:account_types_filter] || all_types)
      @search = session[:account_search].to_s
    end

    # While searching, each type's rows are the matches themselves (flat,
    # regardless of parent_id) instead of the usual root-accounts-down tree,
    # since a match could be buried several levels deep.
    matched_ids = Account.search_by_name(@search).map(&:id) if @search.present?

    @accounts_by_type = @selected_types.each_with_object({}) do |type, hash|
      roots = if matched_ids
        Account.where(account_type: type, id: matched_ids).order(:name)
      else
        Account.where(account_type: type, parent_id: nil).order(:name)
      end
      hash[type] = roots if roots.any?
    end
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit
  end

  # POST /accounts or /accounts.json
  def create
    @account = Account.new(account_params)

    respond_to do |format|
      if @account.save
        format.html { redirect_to accounts_path, notice: "Account was successfully created." }
        format.json { render json: @account, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /accounts/1 or /accounts/1.json
  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to accounts_path, notice: "Account was successfully updated.", status: :see_other }
        format.json { render json: @account, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts/1 or /accounts/1.json
  def destroy
    if @account.destroy
      respond_to do |format|
        format.html { redirect_to accounts_path, notice: "Account was successfully destroyed.", status: :see_other }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to accounts_path, alert: @account.errors.full_messages.to_sentence, status: :see_other }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def account_params
      params.expect(account: [ :name, :account_type, :description, :cash_flow_category, :parent_id ])
    end
end
