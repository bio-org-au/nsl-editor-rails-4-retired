class NameChildrenRefresherJob 
  include SuckerPunch::Job
  
  def perform(name_id,username)
    total = 0
    Rails.logger.info("Performing NameChildrenRefresherJob - a SuckerPunch::Job. May be asynchronous")
    ActiveRecord::Base.connection_pool.with_connection do 
      name = Name.find(name_id)
      total = name.refresh_tree(username)
    end
    return total
  end
end
