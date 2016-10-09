require_relative './message'

class Attachment
  attr_reader :attachment, :filename

  def initialize(attachment)
    @attachment = attachment
    @filename = attachment.filename
  end

  def as_json
    {
      filename: attachment.filename
    }
  end

  def outlook_message?
    inspect.include?("Outlook Message")
  end

  def valid?
    !data.is_a?(Ole::Storage::Dirent)
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

  def can_convert_to_pdf?
    %w[.doc .docx .ppt .pptx .xls .xlsx .rtf .txt].include?(File.extname(filename))
  end

  def write_as_pdf_to(final_path)
    return write_to(final_path) unless can_convert_to_pdf?

    write_to(final_path)
    `cd "#{File.dirname(final_path)}" && soffice --convert-to pdf "#{final_path}" --headless`

    pdf_path = final_path.gsub(/#{File.extname(final_path)}$/, ".pdf")
    @filename = File.basename(pdf_path)
  end
end
