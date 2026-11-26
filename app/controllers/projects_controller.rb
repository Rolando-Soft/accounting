class ProjectsController < ApplicationController
  before_action :set_project, only: %i[edit update destroy]

  def index
    @projects = Project.order(:name)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to projects_path, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to projects_path, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @project.destroy
      redirect_to projects_path, notice: "Project was successfully destroyed.", status: :see_other
    else
      redirect_to projects_path, alert: @project.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.expect(project: [:name, :code, :status])
  end
end
