class WorkspacesController < ApplicationController
  before_action :set_workspace, only: %i[edit update destroy delete_confirm]

  def index
    @workspaces = Workspace.order(:name)
  end

  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(workspace_params)
    if @workspace.save
      redirect_to workspaces_path, notice: "Workspace was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workspace.update(workspace_params)
      redirect_to workspaces_path, notice: "Workspace was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # The confirmation page (not the destroy action) is what shows what will
  # be deleted; destroy itself just requires the typed name to match.
  def destroy
    if params[:confirmation_name] != @workspace.name
      return redirect_to workspaces_path, alert: "Workspace name didn't match — nothing was deleted."
    end

    name = @workspace.name
    @workspace.destroy_everything!
    redirect_to workspaces_path, notice: "Workspace \"#{name}\" and all its data were deleted."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to workspaces_path, alert: e.record.errors.full_messages.to_sentence
  end

  def delete_confirm
  end

  def switch
    workspace = Workspace.find(params[:id])
    session[:workspace_id] = workspace.id
    redirect_back fallback_location: root_path, notice: "Switched to #{workspace.name}."
  end

  private
  def set_workspace
    @workspace = Workspace.find(params[:id])
  end

  def workspace_params
    params.expect(workspace: [:name])
  end
end
