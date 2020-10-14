class Orm

    ATTRIBUTES = {
        :id => "INTEGER PRIMARY KEY",
        :name => "TEXT",
        :location => "TEXT",
        :occupation => "TEXT"
    } # attributes hash is editable from class to class

    ATTRIBUTES.keys.each do |attribute_name|
        attr_accessor attribute_name
    end

    def destroy 
        sql <<-SQL
        DELETE FROM #{self.class.table_name} WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.id)
    end

    def self.table_name
        "#{self.to_s.downcase}s"
    end

    def self.find(id)
        sql = <<-SQL
        SELECT * FROM #{self.table_name} WHERE id = ?
        SQL

        rows = DB[:conn].execute(sql, id)
        self.reify_from_row(rows.first)
    end

    def self.reify_from_row(row)
        self.new.tap do |o|
            ATTRIBUTES.keys.each.with_index do |attribute_name, i|
                o.send("#{attribute_name}=", row[i])
            end
        end
    end

    def self.create_sql
        ATTRIBUTES.collect{|attribute_name, schema| "#{attribute_name} #{schema}"}.join(", ")
    end

    
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS #{self.table_name} (

        )
end