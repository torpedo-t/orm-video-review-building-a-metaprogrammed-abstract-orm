class Orm

    ATTRIBUTES = {
        :id => "INTEGER PRIMARY KEY",
        :name => "TEXT",
        :location => "TEXT",
        :occupation => "TEXT"
    } # attributes hash is editable from class to class
      # this is our point of introspection      

    ATTRIBUTES.keys.each do |attribute_name|
        attr_accessor attribute_name
        # this method assigns each key from our ATTRIBUTES hash 
        # as an attr_accessor for the class
    end

    def destroy 
        sql <<-SQL
        DELETE FROM #{self.class.table_name} WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.id)
        # this method will delete the object with corresponding id
    end

    def self.table_name
        "#{self.to_s.downcase}s"
        # this method is built, so that we can string interpolate the method 
        # later down the road in our methods to refer to the table name abstractly
    end

    def self.find(id)
        sql = <<-SQL
        SELECT * FROM #{self.table_name} WHERE id = ?
        SQL

        rows = DB[:conn].execute(sql, id)
        if rows.first
          self.reify_from_row(rows.first) 
        else
            nil
        end
        # this method will select a row from the table where the id equals
        # the id of the argument passed into the method
    end

    def self.reify_from_row(row)
        self.new.tap do |o|
            ATTRIBUTES.keys.each.with_index do |attribute_name, i|
                o.send("#{attribute_name}=", row[i])
            # creates a new instance of the class and also assigns the object with
            # attributes from the keys within the ATTRIBUTES hash
            end
        end
    end

    def self.create_sql
        ATTRIBUTES.collect{|attribute_name, schema| "#{attribute_name} #{schema}"}.join(", ")
        # we create this method to return our ATTRIBUTES hash as a string
        # "id INTEGER PRIMARY KEY,
        # title TEXT,
        # content TEXT"
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS #{self.table_name} (
        #{self.create_sql}
        )
        SQL

        DB[:conn].execute(sql)
        # if a table, with this name, doesn't exist, create one with that name.
    end

    def save
        # if the object has been saved before, then call update
        persisted? ? update : insert
        # otherwise call insert
    end

    def persisted?
        !!self.id
        # boolean expression, that will return true or false
        # if the record is exists (theres an object stored in our database with matching id), it returns true
    end

    def insert 
        sql = <<-SQL
        INSERT INTO #{self.class.table_name} (#{self.class.attribute_names_for_insert}) VALUES (#{self.class.question_marks_for_insert})
        SQL

        DB[:conn].execute(sql, *attribute_values) # *attribute_values = splat . It allows us to dynamically send the information as individual arguments. Needs to be a method defined that returns the attribute values.
        self.id = DB[:conn].execute("SELECT last_insert_rowid();").flatten.first
        # this method will insert an instance into the table
        # also assigns the instance an id
        # our sql before went like
        # INSERT INTO posts (title, content) VALUES (?, ?)
    end

    def self.attribute_names_for_insert
        ATTRIBUTES.keys[1..-1].join(",")
        # this method should return every key from the ATTRIBUTES hash except id
        # joined by a comma
        # so that we could call on it in our #insert method
    end

    def self.question_marks_for_insert
        (ATTRIBUTES.keys.size-1).times.collect{"?"}.join(",")
        # this method should count and collect the number of keys within
        # our ATTRIBUTES hash (except the id), and return to us a string of ?'s separated
        # by a comma, so we can string interpolate it in our #insert method
        # so if we had 3 keys we would want to return "(?, ?, ?)"
    end

    def attribute_values
        ATTRIBUTES.keys[1..-1].collect{|attribute_name| self.send(attribute_name)}
        # this method should return an array like
        # ["Orm Name", "Orm Location", "Orm Occupation"]
        # we use this method to call on it like so *attribute_values within the #insert, #update methods
    end

    def self.sql_for_update
        ATTRIBUTES.keys[1..-1].collect{|attribute_name| "#{attribute_name} = ?"}.join(",")
        # return to me all of the keys besides id
        # return to me all of the keys in a variable called attribute_name
        # build a string called attribute_name = ?
        # and then join those individual strings with a comma
    end
    
    def update 
        sql = <<-SQL
        UPDATE #{self.table_name} SET #{self.class.sql_for_update} WHERE id = ?
        SQL

        DB[:conn].execute(sql, *attribute_values, self.id)
        # this method will update an instance of the class without duplicating it in our table
    end
end