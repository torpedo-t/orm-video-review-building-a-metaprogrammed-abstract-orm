class Orm

    ATTRIBUTES = {
        :id => "INTEGER PRIMARY KEY",
        :name => "TEXT",
        :location => "TEXT",
        :occupation => "TEXT"
    } # attributes hash is editable from class to class
      # this is our point of introspection  
      
    def self.attributes
        ATTRIBUTES
    end  
      
    ATTRIBUTES.keys.each do |attribute_name|
        attr_accessor attribute_name
        # this method assigns each key from our ATTRIBUTES hash 
        # as an attr_accessor for the class
    end

    include Persistable::InstanceMethods
    extend Persistable::ClassMethods
end