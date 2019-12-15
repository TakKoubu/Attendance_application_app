class AttendancesController < ApplicationController
  include AttendancesHelper
  
  before_action :set_user, only: [:edit_one_month, :update_one_month, :working_employee_list, :current_month_status, :overtime_application, :overtime_application_notice, :update_overtime_application_notice]
  before_action :logged_in_user, only: [:update, :edit_one_month, :overtime_application, :overtime_application_notice, :update_overtime_application_notice]
  before_action :admin_or_correct_user,  only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。再度登録をお願いします。"
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec:0))
        flash[:success] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
      redirect_to user_url(@user)
    elsif @attendance.started_at.present? && @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec:0))
        flash[:success] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
      redirect_to user_url(@user)
    end
  end
  
  def edit_one_month
  end
  
  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      #繰り返し処理により、勤怠編集処理を実施する
      if attendances_invalid?
        attendances_params.each do |id, item|
          attendance = Attendance.find(id)
          attendance.update_attributes!(item)
        end
        flash[:success] = "1ヶ月分の勤怠編集更新に成功しました"
        redirect_to user_url(@user)
      else
        flash[:danger] = "不正な時間入力がありました、再入力してください。"
        redirect_to attendances_edit_one_month_user_url(@user, params[:date])
      end
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効なデータを入力しました。再度編集をお願いします。"
    redirect_to attendances_edit_one_month_user_url(@user)
  end
  
  #残業申請モーダル
  def overtime_application_info
    @attendance = Attendance.find(params[:id])
    @user = User.find(@attendance.user_id)
  end
  
  #残業申請更新
  def overtime_application
    @attendance = @user.attendances.find_by(worked_on: params[:attendance][:day])
    if params[:attendance][:endplans_time].blank?  || params[:attendance][:business_outline].blank?
      flash[:warning] = "必須箇所が空欄です。"
    else
      @attendance.update_attributes(update_overtime_params)
      flash[:success] = "残業申請が完了しました。"
    end
    redirect_to @user
  end
  
  #残業申請のお知らせモーダル
  def overtime_application_notice
  end
  
  #残業申請のお知らせ表示時の更新処理
  def update_overtime_application_notice
    @attendances = Attendance.all
    @attendances.each do |attendance|
      if attendance.decision == 2
         attendance.update_attributes(update_overtime_notice_params)
         flash[:success] = "残業申請が承認されました"
      elsif attendance.decision == 3
         attendance.update_attributes(update_overtime_notice_params)
         flash[:danger]  = "残業申請が否認されました"
      end
    end
    redirect_to @user
  end
  
  private
  
  # 1ヶ月分の勤怠情報を扱います。
  def attendances_params
    params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
  end
  
  #残業申請更新をします
  def update_overtime_params
    params.require(:attendance).permit(:endplans_time, :over_next_day, :business_outline, :overtime_order_id)
  end

  def update_overtime_notice_params
    params.require(:user).permit(attendances: [:decision, :agreement])[:attendances]
  end
    
  # 管理権限者、または現在ログインしているユーザーを許可します。
  def admin_or_correct_user
    @user = User.find(params[:user_id]) if @user.blank? 
    unless current_user.admin? || current_user?(@user)
      flash[:danger] = "編集・操作権限がありません"
      redirect_to root_url
    end
  end
end