module Persistable
    module ClassMethods

        def table_name
            "#{self.to_s.downcase}s"
            # this method is built, so that we can string interpolate the method 
            # later down the road in our methods to refer to the table name abstractly
        end

        #Orm.create(:name => "John") #=> #<Orm: @id=1, @name="John"
        def create(attributes_hash)
            self.new.tap do |o|
                self.attributes_hash.keys.each.with_index do |attribute_name, i|
                    o.send("#{attribute_name}=", row[i])
                end
                o.save
            end
        end

        def find(id)
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
        
        def reify_from_row(row)
            self.new.tap do |o|
                self.attributes.keys.each.with_index do |attribute_name, i|
                    o.send("#{attribute_name}=", row[i])
                # creates a new instance of the class and also assigns the object with
                # attributes from the keys within the ATTRIBUTES hash
                end
            end
        end
        
        def create_sql
            self.attributes.collect{|attribute_name, schema| "#{attribute_name} #{schema}"}.join(", ")
            # we create this method to return our ATTRIBUTES hash as a string
            # "id INTEGER PRIMARY KEY,
            # title TEXT,
            # content TEXT"
        end
        
        def create_table
            sql = <<-SQL
            CREATE TABLE IF NOT EXISTS #{self.table_name} (
            #{self.create_sql}
            )
            SQL
        
            DB[:conn].execute(sql)
            # if a table, with this name, doesn't exist, create one with that name.
        end

        def attribute_names_for_insert
            self.attributes.keys[1..-1].join(",")
            # this method should return every key from the ATTRIBUTES hash except id
            # joined by a comma
            # so that we could call on it in our #insert method
        end
        
        def question_marks_for_insert
            (self.attributes.keys.size-1).times.collect{"?"}.join(",")
            # this method should count and collect the number of keys within
            # our ATTRIBUTES hash (except the id), and return to us a string of ?'s separated
            # by a comma, so we can string interpolate it in our #insert method
            # so if we had 3 keys we would want to return "(?, ?, ?)"
        end

        def sql_for_update
            self.attributes.keys[1..-1].collect{|attribute_name| "#{attribute_name} = ?"}.join(",")
            # return to me all of the keys besides id
            # return to me all of the keys in a variable called attribute_name
            # build a string called attribute_name = ?
            # and then join those individual strings with a comma
        end
    end

    module InstanceMethods

        def destroy 
            sql <<-SQL
            DELETE FROM #{self.class.table_name} WHERE id = ?
            SQL
        
            DB[:conn].execute(sql, self.id)
            # this method will delete the object with corresponding id
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

        def attribute_values
            self.class.attributes.keys[1..-1].collect{|attribute_name| self.send(attribute_name)}
            # this method should return an array like
            # ["Orm Name", "Orm Location", "Orm Occupation"]
            # we use this method to call on it like so *attribute_values within the #insert, #update methods
        end
        
        def update 
            sql = <<-SQL
            UPDATE #{self.table_name} SET #{self.class.sql_for_update} WHERE id = ?
            SQL
        
            DB[:conn].execute(sql, *attribute_values, self.id)
            # this method will update an existing instance of the class without duplicating it in our table
        end

    end
end
