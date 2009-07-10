module WhatColumn
  class Columnizer

    HEADER = "# === List of columns ==="
    FOOTER = "# ======================="
    INCREMENT = "  "

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
    
    def with_each_file_in_rails_directory(*args)
      dirs = [RAILS_ROOT] + args + ['**', '*']
      Dir[File.join(*dirs)].each do |file|
        next if File.directory?(file)
        yield file
      end
    end

    private

    def rewrite_file(file)
      file.rewind            
      output_lines = []
      
      file.readlines.each_with_index do |line, index|
        yield output_lines, line, index
      end
      
      file.pos = 0
      file.print output_lines
      file.truncate(file.pos)
    end

    def model_columns_details(ar_class)
      max_width = ar_class.columns.map {|c| c.name.length + 1}.max
      # the format string is used to line up the column types correctly
      format_string = "#{INCREMENT}#   %-#{max_width}s: %s \n"

      ["\n" + INCREMENT + HEADER + "\n"] + 
      ar_class.columns.map do |column|
        format_string % [column.name, column.type.to_s]
      end + 
      [INCREMENT + FOOTER + "\n\n"]
    end

    
    def add_column_details_to_file(filepath)
      File.open(filepath, "r+") do |file|
        source_code = file.read

        ar_class = source_code.match(/^\s*class (.*?)\s*\</) && $1.constantize
        return unless ar_class
        return unless class_can_be_columnized?(ar_class)

        rewrite_file(file) do |output_lines, line, index|          
          output_lines << line
          if line.match(/^\s*class (#{ar_class})\s*\</)
            output_lines << model_columns_details(ar_class)
            output_lines.flatten!
          end
        end
      end
    end

    def remove_column_details_from_file(filepath)
      File.open(filepath, 'r+') do |file|
        lines = file.readlines
        removing_what_columns = false
        out = []
        lines.each_with_index do |line, index|
          if line_has_header?(line)
            removing_what_columns = true
            # And remove previous empty line
            out.pop if out.last == "\n"
          end


          previous_line = index > 0 ? lines[index - 1] : ""
          if should_keep_line?(removing_what_columns, line, previous_line)
            out << line
          end

          if line_has_footer?(line)
            removing_what_columns = false
          end

        end    
        file.pos = 0
        file.puts out
        file.truncate(file.pos)      
      end
    end

    def should_keep_line?(removing_what_columns, line, previous_line)
      !((removing_what_columns and line.match(/^\s*#/)) or (line_has_footer?(previous_line) and line == "\n"))
    end
    
    def line_has_header?(line)
      line.match(/^\s*#{HEADER}\s*$/)
    end
      
    def line_has_footer?(line)
      line.match(/^\s*#{FOOTER}\s*$/)
    end
    
    def class_can_be_columnized?(class_to_check)
      class_to_check.respond_to?(:table_exists?) and class_to_check.table_exists? and class_to_check.respond_to?(:columns)
    end

  end
end