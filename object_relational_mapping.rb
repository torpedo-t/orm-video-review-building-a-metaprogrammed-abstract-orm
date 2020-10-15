class Orm
    # the class only needs to house the hash of attributes as well as a reader method
    # that returns our constant referring to our hash of attributes
    # which in this case is ATTRIBUTES
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