require 'digest'
require_relative './message'

class Attachment
  attr_reader :attachment, :original_filename

  def initialize(attachment)
    @attachment = attachment
    @original_filename = attachment.filename
  end

  def as_json
    {
      filename: filename
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

  def write_to(dir)
    path = File.join(dir, unique_name)
    File.open(path, "wb") { |f| f.write(raw_data) }
  end

  def can_convert_to_pdf?
    %w[.doc .docx .ppt .pptx .xls .xlsx .rtf .txt]
      .include?(File.extname(original_filename))
  end

  def write_as_pdf_to_dir(dir)
    write_to(dir)

    return unless can_convert_to_pdf?

    `cd "#{dir}" && soffice --convert-to pdf "#{File.join(dir, unique_name)}" --headless`
    # pdf version now available at `dir/filename`
  end

  def unique_name
    @unique_name ||= "#{Digest::MD5.hexdigest(raw_data)}-#{original_filename}"
  end

  def raw_data
    return @raw_data if @raw_data
    data.rewind
    @raw_data = data.read
  end

  def filename
    @filename ||= can_convert_to_pdf? ?
      unique_name.gsub(/#{File.extname(original_filename)}$/, ".pdf") :
      unique_name
  end
end
