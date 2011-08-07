class CatsController < ActionController::Base
  
  before_filter :find_commentable
  
  def index
    @cats = nil
  end
  
  protected
  
  def find_commentable
    #do something awesome
  end
end