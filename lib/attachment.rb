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

  def write_to(path)
    data = attachment.data
    data.rewind

    File.open(path, "wb") { |f| f.write(data.read) }
  end

  def write_as_pdf_to(final_path)
    return write_to(final_path) if File.extname(filename) == ".pdf"

    original_tmp_path = "tmp/#{filename}"
    pdf_tmp_path = "#{File.basename(filename, '.*')}.pdf"

    write_to(tmp_path)
    `soffice --convert-to pdf #{original_tmp_path} --headless`

    FileUtils.mv(pdf_tmp_path, final_path)
  end
end
