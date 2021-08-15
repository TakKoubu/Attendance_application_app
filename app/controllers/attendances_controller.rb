class AttendancesController < ApplicationController
  include AttendancesHelper

  before_action :set_one_month, only: :edit_one_month
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  
  def edit_one_month
    @attendance = Attendance.find_by(user_id: @user)

    superiors = User.where.not(id: @user.id).superior
    @superiors = {}
    superiors.each do |superior|
      @superiors[superior.name] = superior.id
    end

    if @attendance.change_approval
      @change_approval = @attendance.change_approval
    else
      @change_approval = @attendance.build_change_approval(user_id: @user.id)
    end
    @change_approval.save!
  end
  
  def update_one_month
    if attendances_invalid?
      attendances_params.each do |id, item|
        change_approval = Attendance.find(id).change_approval
        if change_approval.present?
          change_approval.update_attributes(item)

          superiors = User.where.not(id: @user.id).superior
          @superiors = {}
          superiors.each do |superior|
            @superiors[superior.name] = superior.id
            change_approval.update(superior_id: superior.id)
          end
        end
      end
      flash[:success] = "勤怠更新に成功しました(指示者確認㊞を選択していない場合は、上長への申請が出来ていません)。"
      redirect_to user_url(@user)
    else
      flash[:danger] = "不正な時間入力がありました。再度ご確認ください。"
      render :edit_one_month
    end
  end
   
  def update
    @attendance = Attendance.find(params[:id])
    
    if @attendance.start_time.nil?
      if @attendance.update_attributes(start_time: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.end_time.nil?
      if @attendance.update_attributes(end_time: Time.current.change(sec: 0))
        flash[:info] = "お疲れさまでした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  private
  
  def set_user
    @user = User.find(params[:user_id])
  end

  def attendances_params
    params.require(:user).permit(attendances: [:start_time, :end_time, :application_situation, :user_id, :superior_id])[:attendances]
  end
end