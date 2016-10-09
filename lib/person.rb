class Person
  EMAIL_REGEX = /<(.+?@.+?)>$/

  def initialize(line)
    @line = line.strip
  end

  def name
    return unless has_name?

    @name ||= line
      .match(/^(.+)\s+#{EMAIL_REGEX}/)
      &.[](1)
      &.gsub(/"/, '')
  end

  def email
    @email ||= (has_name? ? line.match(EMAIL_REGEX)[1] : line).downcase
  end

  def as_json
    {
      name: name,
      email: email
    }
  end

  private

  def line
    @line
  end

  def has_name?
    !!line.match(EMAIL_REGEX)
  end
end
