class UsersController < ActionController::Base
  
  
  def index
    @users = Freelancer.find_all_by_name(param[:name])
  end
end