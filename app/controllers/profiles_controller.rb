class ProfilesController < ApplicationController
  def update
    name = params[:name].to_s.strip.first(40)
    if name.present?
      session[:user_name] = name
      redirect_back_or_to root_path, notice: "Hi #{name}!"
    else
      redirect_back_or_to root_path, alert: "Please enter a name."
    end
  end
end
