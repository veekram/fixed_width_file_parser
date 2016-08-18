require "fixed_width_file_parser/version"

module FixedWidthFileParser
  # Parse a fixed width file, yielding the proper data for each line based on the fields passed in
  #
  # @param filepath [String] The path to the file to be parsed.
  # @param fields [Array(Hash{name => String, position => Range|Integer})] An array of field hashes, each containing a `name` and a `position`.
  # @yield [Hash] Yields a hash object based on the fields provided.
  #
  # @example
    # filepath = 'path/to/file'
    # fields = [
    #   { name: 'first_name', position: 0..10 },
    #   { name: 'middle_initial', position: 11 },
    #   { name: 'last_name', position: 12..25 }
    # ]
    #
    # FixedWidthFileParser.parse(filepath, fields) do |row|
    #   puts row
    # end

  def self.parse(filepath, fields, options = {})
    # Set options, or use default
    force_utf8_encoding = options.fetch(:force_utf8_encoding, true)

    # Verify `filepath` is a String
    unless filepath.is_a?(String)
      raise '`filepath` must be a String'
    end

    # Verify `fields` is an array
    if fields.is_a?(Array)
      # Verify fields is not emtpy
      if fields.empty?
        raise '`fields` must contain at least 1 item'
      end
    else
      raise '`fields` must be an Array'
    end

    # Verify each field has a `name` and `position`
    unless fields.all? { |item| item.key?(:name) && item.key?(:position) }
      raise 'Each field hash must include a `name` and a `position`'
    end

    # Verify that each `position` is either a Range or an Integer
    unless fields.all? { |item| item[:position].is_a?(Range) || item[:position].is_a?(Integer) }
      raise "Each field's `position` must be a Range or an Integer"
    end

    GC.start

    file = File.open(filepath)

    while !file.eof?
      line = file.readline
      # If the current line is blank, skip to the next line
      # chomp to remove "\n" and "\r\n"
      next if line.chomp.empty?

      # Force UTF8 encoding if force_utf8_encoding is true (defaults to true)
      if force_utf8_encoding
        # Handle UTF Invalid Byte Sequence Errors
        # e.g. https://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
        line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      end

      line_fields = {}
      fields.each do |field|
        line_fields[field[:name].to_sym] = line[ field[:position] ].nil? ? nil :  line[ field[:position] ].strip
      end

      yield(line_fields)
    end

    GC.start

    file.close
  end

  def self.parse_in_batches(filepath, fields, options = {})
    # Set options, or use default
    batch_size = options.fetch(:batch_size, 1000)
    force_utf8_encoding = options.fetch(:force_utf8_encoding, true)

    # Verify `filepath` is a String
    unless filepath.is_a?(String)
      raise '`filepath` must be a String'
    end

    # Verify `fields` is an array
    if fields.is_a?(Array)
      # Verify fields is not emtpy
      if fields.empty?
        raise '`fields` must contain at least 1 item'
      end
    else
      raise '`fields` must be an Array'
    end

    # Verify each field has a `name` and `position`
    unless fields.all? { |item| item.key?(:name) && item.key?(:position) }
      raise 'Each field hash must include a `name` and a `position`'
    end

    # Verify that each `position` is either a Range or an Integer
    unless fields.all? { |item| item[:position].is_a?(Range) || item[:position].is_a?(Integer) }
      raise "Each field's `position` must be a Range or an Integer"
    end

    GC.start

    File.open(filepath) do |file|
      file.lazy.drop(1).each_slice(batch_size) do |lines|
        lines.each do |line|
          # If the current line is blank, skip to the next line
          # chomp to remove "\n" and "\r\n"
          next if line.chomp.empty?

          # Force UTF8 encoding if force_utf8_encoding is true (defaults to true)
          if force_utf8_encoding
            # Handle UTF Invalid Byte Sequence Errors
            # e.g. https://robots.thoughtbot.com/fight-back-utf-8-invalid-byte-sequences
            line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          end

          line_fields = {}
          fields.each do |field|
            line_fields[field[:name].to_sym] = line[ field[:position] ].nil? ? nil :  line[ field[:position] ].strip
          end

          yield(line_fields)
        end

        GC.start
      end
    end
  end
end
