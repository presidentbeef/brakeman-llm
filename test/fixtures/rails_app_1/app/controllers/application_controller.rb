class ApplicationController < ActionController::Base
  def vulnerable_method
    eval(params[:x])
  end
end
