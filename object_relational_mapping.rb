class Orm

    ATTRIBUTES = {
        :id => "INTEGER PRIMARY KEY",
        :name => "TEXT",
        :location => "TEXT",
        :occupation => "TEXT"
    } # attributes hash is editable from class to class

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
        self.reify_from_row(rows.first)
        # this method will select a row from the table where the id equals
        # the id of the argument passed into the method
    end

    def self.reify_from_row(row)
        self.new.tap do |o|
            ATTRIBUTES.keys.each.with_index do |attribute_name, i|
                o.send("#{attribute_name}=", row[i])
            # creates a new instance of the class and also 
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
    end

    def save
        # if the past has been saved before, then call update
        persisted? ? update : insert
        # otherwise call insert
    end

    def persisted?
        !!self.id
    end

    def insert 
        sql = <<-SQL
        INSERT INTO #{self.class.table_name} (#{self.class.attribute_names_for_insert}) VALUES (#{self.class.question_marks_for_insert})
        SQL

        DB[:conn].execute(sql, *attribute_values)
        self.id = DB[:conn].execute("SELECT last_insert_rowid();").flatten.first
    end

    def self.attribute_names_for_insert
        ATTRIBUTES.keys[1..-1].join(",")
    end

    def self.question_marks_for_insert
        (ATTRIBUTES.keys.size-1).times.collect{"?"}.join(",")
    end

    def attribute_values
        ATTRIBUTES.keys[1..-1].collect{|key| self.send(key)}
    end

    def self.sql_for_update
        ATTRIBUTES.keys[1..-1].collect{|attribute_name| "#{attribute_name} = ?"}.join(",")
    end
    
    def update 
        sql = <<-SQL
        UPDATE #{self.table_name} SET #{self.class.sql_for_update} WHERE id = ?
        SQL

        DB[:conn].execute(sql, *attribute_values, self.id)
    end
end