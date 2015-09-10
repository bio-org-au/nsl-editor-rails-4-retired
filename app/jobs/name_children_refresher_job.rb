class NameChildrenRefresherJob 
  include SuckerPunch::Job
  
  def perform(name_id)
    total = 0
    ActiveRecord::Base.connection_pool.with_connection do 
      name = Name.find(name_id)
      name.combined_children.each do |child|
        total += child.refresh_constructed_name_fields!
      end
    end
    return total
  end
end
