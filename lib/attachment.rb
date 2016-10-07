require_relative './message'

class Attachment
  attr_reader :attachment

  def initialize(attachment)
    @attachment = attachment
  end

  def filename
    attachment.filename
  end

  def as_json
    {
      filename: attachment.filename
    }
  end

  def outlook_message?
    inspect.include?("Outlook Message")
  end

  def data
    attachment.data
  end

  def to_message
    ::Message.new(attachment.data)
  end

  def write_to(path)
    data.rewind

    File.open(path, "wb") { |f| f.write(data.read) }
  end

  def write_as_pdf_to(final_path)
    return write_to(final_path) if File.extname(filename) == ".pdf"

    original_tmp_path = "/tmp/#{filename}"
    pdf_tmp_path = "/tmp/#{File.basename(filename, '.*')}.pdf"

    write_to(original_tmp_path)
    `soffice --convert-to pdf #{original_tmp_path} --headless`

    FileUtils.mv(pdf_tmp_path, final_path)
    FileUtils.rm(original_tmp_path)
  end
end
