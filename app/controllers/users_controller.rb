class UsersController < ApplicationController
  before_action :set_team, only: [:create, :index, :new, :edit, :update]

  def create
    service = UserCreationService.new(team: @team, params: create_user_params)
    service.call
    @user = service.user
    case service.result
    when :ok
      flash[:notice] = 'User created'
      redirect_to team_path(id: @team.id)
    when :existing_ok
      flash[:notice] = 'Existing user added to team'
      redirect_to team_path(id: @team.id)
    else
      render :new
    end
  end

  def index
    if @team.present?
      @users = @team.users
    else
      @users = User.all
    end

  end

  def new
    @user = User.new
    role = validate_role
    @role = role
  end

  def edit
    @user = User.find params[:id]
    @role = @team.role
  end

  def update
    @user = User.find params[:id]
    if @user.update(create_user_params)
      flash[:notice] = 'User details updated'
      redirect_to team_path(id: @team.id)
    else
      redirec_to user_path(@user)
    end
  end

  private

  def validate_role
    if params.require(:role) == @team.role
      params[:role]
    else
      raise "Role parameter #{params[:role]} does not match team's roles."
    end
  end

  def create_user_params
    params.require(:user).permit(
      :full_name,
      :email,
    )
  end

  def set_team
    if params.key? :team_id
      @team = Team.find(params[:team_id])
    end
  end
end