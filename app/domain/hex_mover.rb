# frozen_string_literal: true

# Moves a star system or a rogue stellar object to another hex. The destination
# is either a parsec id (clicked on the move modal's map) or a sector plus
# four digit sector hex code. It may be in any sector.
class HexMover
  Result = Struct.new(:success, :error, :parsec, keyword_init: true) do
    def success? = success
  end

  def initialize(record, parsec_id: nil, sector: nil, hex_code: nil)
    @record = record
    @parsec_id = parsec_id.presence
    @sector = sector
    @hex_code = hex_code.to_s.strip
  end

  def call
    target = @parsec_id ? Parsec.find_by(id: @parsec_id) : parsec_from_address
    return target if target.is_a?(Result)
    return failure('That hex does not exist.') if target.nil?
    return failure('It is already in that hex.') if @record.parsec_id == target.id

    if @record.is_a?(StarSystem) && StarSystem.exists?(parsec_id: target.id)
      return failure('That hex already contains a star system.')
    end

    @record.update!(parsec: target)
    Result.new(success: true, parsec: target)
  rescue ActiveRecord::RecordInvalid => error
    failure(error.record.errors.full_messages.to_sentence)
  end

  private

  # Returns a Parsec, nil, or a failure Result for malformed input.
  def parsec_from_address
    return failure('Choose a sector.') if @sector.nil?
    return failure('Enter the hex as four digits, e.g. 0305.') unless @hex_code.match?(/\A\d{4}\z/)

    hx = @hex_code[0, 2].to_i
    hy = @hex_code[2, 2].to_i
    return failure('That hex is outside the sector.') unless hx.between?(1, 32) && hy.between?(1, 40)

    ul = @sector.upper_left
    Parsec.find_by(sector_id: @sector.id, x: ul.x + hx - 1, y: ul.y - hy + 1)
  end

  def failure(message) = Result.new(success: false, error: message)
end
