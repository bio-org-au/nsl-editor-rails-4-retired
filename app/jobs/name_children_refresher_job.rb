class NameChildrenRefresherJob 
  include SuckerPunch::Job
  
  def perform(name_id)
    total = 0
    Rails.logger.info("Performing an asynchronous job via SuckerPunch::Job.")
    ActiveRecord::Base.connection_pool.with_connection do 
      name = Name.find(name_id)
      name.combined_children.each do |child|
        Rails.logger.info("Performing a job via SuckerPunch::Job.refresh_constructed_name_fields! May be asynchronous.")
        total += child.refresh_constructed_name_fields!
      end
    end
    return total
  end
end
