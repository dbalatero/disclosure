class Attachment
  attr_reader :attachment

  def initialize(attachment)
    @attachment = attachment
  end

  def filename
    attachment.filename
  end

  def write_to(path)
    data = attachment.data
    data.rewind

    File.open(path, "wb") { |f| f.write(data.read) }
  end
end
