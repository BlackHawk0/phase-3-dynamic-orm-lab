require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true
        DB[:conn].execute("pragma table_info('#{self.table_name}')").map {|hash| hash["name"]}.compact
    end

    def initialize (options={})
        options.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if  {|col_name| col_name == "id"}.join(", ")
    end

    def  values_for_insert
        self.class.column_names.map do |col|
            # invoke the col method using send and return the value unles the column is nil
            "'#{send(col)}'" unless send(col).nil?
        # remove nil values and join the array to a string
        end.compact.join(", ")
    end

    def save
        DB[:conn].execute("INSERT INTO #{self.table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
    end

    def self.find_by(hash)
        if hash.values[0].is_a? Integer
            DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{hash.keys[0]} = #{hash.values[0]}")
        else
            DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{hash.keys[0]} = '#{hash.values[0]}'")
        end
    end
end




# other approaches
    # def self.column_names
    #     DB[:conn].results_as_hash = true
    #     # sql = "PRAGMA table_info('#{table_name}')"

    #     # column_names = []

    #     # # get hash of the table information
    #     # table_info = DB[:conn].execute(sql)
    #     # table_info.each do |info|
    #     #     column_names << info["name"]
    #     # end

    #     # # remove nil values
    #     # column_names.compact
    # end