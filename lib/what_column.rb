module WhatColumn
  class Columnizer

    HEADER = "# === List of columns ==="
    FOOTER = "# ======================="
    INCREMENT = "  "
    
    LIST_OF_COLUMNS_REGEXP  = /\n\s*#{HEADER}\s*.*?\s*#{FOOTER}\s*\n/m
    CLASS_DEFINITION_REGEXP = /\n?\s*class (.*?)\s*\<.*?(?:\n|;)/m
                            #        class (User)   < ActiveRecord::Base
    
    def add_column_details_to_models
      remove_column_details_from_models    
      with_each_file_in_rails_directory('app', 'models') do |file|
        add_column_details_to_file(file)
      end
    end
    

    def remove_column_details_from_models
      with_each_file_in_rails_directory('app', 'models') do |file|
        remove_column_details_from_file(file)
      end
    end
    
    private

    def add_column_details_to_file(filepath)
      rewrite_file(filepath) do |source|
        source.gsub(CLASS_DEFINITION_REGEXP) do |definition|
          ar_class = $1.constantize rescue nil
          [definition, model_columns_details(ar_class)].join
        end
      end
    end


    def remove_column_details_from_file(filepath)
      rewrite_file(filepath) do |source|
        source.gsub(LIST_OF_COLUMNS_REGEXP, "\n")
      end
    end


    def with_each_file_in_rails_directory(*args)
      dirs = [RAILS_ROOT] + args + ['**', '*']
      Dir[File.join(*dirs)].each do |file|
        next if File.directory?(file)
        yield file
      end
    end


    def rewrite_file(filepath)
      source = File.read(filepath)
      File.open(filepath, "w") {|file| file.write yield(source) }      
    end


    def model_columns_details(ar_class)
      return unless class_can_be_columnized?(ar_class)
      
      max_width = ar_class.columns.map {|c| c.name.length + 1}.max
      # the format string is used to line up the column types correctly
      format_string = "#{INCREMENT}#   %-#{max_width}s: %s "

      columns = ar_class.columns.map do |column|
        format_string % [column.name, column.type.to_s]
      end.join("\n")

      "\n#{INCREMENT}#{HEADER}\n" + columns + "\n#{INCREMENT}#{FOOTER}\n\n"
    end
    

    def class_can_be_columnized?(class_to_check)
      class_to_check.respond_to?(:table_exists?) and class_to_check.table_exists? and class_to_check.respond_to?(:columns)
    end

  end
end