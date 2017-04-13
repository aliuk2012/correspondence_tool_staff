class AssignmentsController < ApplicationController

  before_action :set_case, only: [:new, :create, :edit, :accept_or_reject, :show_rejected]
  before_action :set_assignment, only: [:edit, :accept_or_reject]
  before_action :validate_response, only: :accept_or_reject

  def new
    authorize @case, :can_assign_case?
    @assignment = @case.assignments.new
    @creating_case = flash[:creating_case]
    flash.keep :creating_case
  end

  def create
    authorize @case, :can_assign_case?

    @assignment = @case.assignments.create(assignment_params.merge(role: 'responding'))
    if @assignment.valid?
      @case.assign_responder(current_user, @assignment.team)
      flash[:notice] = flash[:creating_case] ? t('.case_created') : t('.case_assigned')
      AssignmentMailer.new_assignment(@assignment).deliver_later

      redirect_to case_path @case.id
    else
      render :new
    end
  end

  def edit
    if @assignment
      if @assignment.accepted?
        redirect_to case_path @case, accepted_now: false
      elsif @assignment.rejected?
        redirect_to case_assignments_show_rejected_path @case, rejected_now: false
      else
        authorize @case, :can_accept_or_reject_case?
        render :edit
      end
    else
      flash[:notice] = 'Case assignment does not exist.'
      redirect_to case_path @case
    end
  end

  def accept_or_reject
    authorize @case, :can_accept_or_reject_case?

    if accept?
      @assignment.accept current_user
      redirect_to case_path @assignment.case, accepted_now: true
    elsif valid_reject?
      @assignment.reject current_user, assignment_params[:reasons_for_rejection]
      redirect_to case_assignments_show_rejected_path @case, rejected_now: true
    else
      @assignment.assign_and_validate_state(assignment_params[:state])
      render :edit
    end
  end

  def show_rejected
    @rejected_now = params[:rejected_now]
    render
  end

  private

  def assignment_params
    if params[:assignment]
      params.require(:assignment).permit(
        :state,
        :team_id,
        :reasons_for_rejection
      )
    else
      HashWithIndifferentAccess.new
    end
  end

  def set_assignment
    if Assignment.exists?(id: params[:id])
      @assignment = Assignment.find(params[:id])
    end
  end

  def set_case
    @case = Case.find(params[:case_id])
    @case_transitions = @case.transitions.decorate
  end

  def validate_response
    if assignment_params[:state].nil?
      @assignment.errors.add(:state, :blank)
    end
  end

  def accept?
    assignment_params[:state] == 'accepted'
  end

  def valid_reject?
    assignment_params[:state] == 'rejected' &&
      assignment_params[:reasons_for_rejection].match(/\S/)
  end
end
