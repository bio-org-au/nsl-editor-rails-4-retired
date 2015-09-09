class NameChildrenRefresherJob 
  include SuckerPunch::Job
  
  def perform(name_id)
    total = 0
    ActiveRecord::Base.connection_pool.with_connection do 
      name = Name.find(name_id)
      name.children.each do |child|
        total += child.set_names!
      end
    end
    return total
  end
end
