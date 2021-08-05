class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :update_index, :destroy]
  
  def index
    @users = User.all
  end
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = 'ユーザを登録しました。'
      redirect_to root_url
    else
      flash.now[:danger] = 'ユーザの登録に失敗しました。'
      render 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @user.update_attributes(user_params)
      flash[:success] = 'ユーザー情報の更新に成功しました。'
      redirect_to root_url
    else
      flash.now[:danger] = 'ユーザー情報の更新に失敗しました。'
      render 'edit'
    end
  end
  
  def update_index
    if @user.update_attributes(user_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
      redirect_to root_url
    else
      flash.now[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
      @users = User.all
      render 'index'
    end
  end
  
  def destroy
    @user.destroys
    flash[:success] = 'ユーザーを削除しました。'
    redirect_back(fallback_location: root_path)
  end
  
  def import
    User.import(params[:file])
    redirect_to users_url
  end
  
  private

  def user_params
    params.require(:user).permit(:name, :uid, :password, :password_confirmation, :role)
  end
  
  def set_user
    @user = User.find(params[:id])
  end
end
