class AdminController < ApplicationController
  before_filter :staff_required
  
  def show
    @connections = Connection.all
  end
  
  def jobs
    @jobs = Delayed::Job.all
  end
  
  def accounts
    @accounts = Account.paginate(:order => "created_at desc", :per_page => 100, :page => params[:page])
  end
end
