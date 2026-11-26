require "bigdecimal"
require "csv"

class MaterialImport
  Result = Struct.new(:rows, :errors, keyword_init: true) do
    def valid?
      errors.empty? && rows.any?
    end
  end

  def self.parse(text)
    result = Result.new(rows: [], errors: [])
    text.to_s.each_line.with_index(1) do |line, number|
      next if line.strip.empty?

      attributes = parse_line(line)
      result.rows << attributes
    rescue ArgumentError, CSV::MalformedCSVError => error
      result.errors << "Line #{number}: #{error.message}"
    end

    result.errors << "Paste at least one material." if result.rows.empty? && result.errors.empty?
    result
  end

  def self.parse_line(line)
    fields = CSV.parse_line(line.chomp, col_sep: ";")
    unless fields&.size == 3
      raise ArgumentError, "Use three fields: description; quantity; unit."
    end

    description, quantity_text, unit = fields.map { |field| field.to_s.strip }
    raise ArgumentError, "Enter a material description." if description.empty?
    raise ArgumentError, "Enter a unit of measure." if unit.empty?

    unless quantity_text.match?(/\A\+?(?:\d+(?:\.\d+)?|\.\d+)\z/) && BigDecimal(quantity_text).positive?
      raise ArgumentError, "Enter a quantity greater than zero, using a dot for decimals."
    end

    { description: description, quantity: BigDecimal(quantity_text), unit_of_measure: unit }
  rescue CSV::MalformedCSVError
    raise ArgumentError, "Check the quotes around fields containing semicolons."
  end
  private_class_method :parse_line
end
