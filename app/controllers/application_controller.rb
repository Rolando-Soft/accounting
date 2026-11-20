class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_workspace

  private
  def set_current_workspace
    Current.workspace = Workspace.find_by(id: session[:workspace_id]) || Workspace.order(:id).first
    session[:workspace_id] = Current.workspace&.id
  end
end
