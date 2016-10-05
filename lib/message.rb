require 'mapi/msg'
require 'pry'

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

class Message
  attr_reader :path, :msg

  def initialize(path)
    @path = path
    @msg = Mapi::Msg.open(path)
  end

  def subject
    msg.subject
  end

  def attachments
    @attachments ||= msg.attachments.map { |attachment| Attachment.new(attachment) }
  end

  def plain_body
    @plain_body ||= begin
      plain = body
        .split(boundary)
        .detect { |chunk| chunk.include?("Content-Type: text/plain") }
        .to_s

      plain.gsub!(/Content-Type: text\/plain/, '')
      plain.gsub!(/\r/, '')
      plain.gsub!(/\n\s+\n/, "\n\n")
      plain.gsub!(/\n{3,}/, "\n\n")

      fix_word_chars!(plain)
      plain.strip!

      plain
    end
  end

  private

  def body
    @body ||= msg.body_to_mime.to_s
  end

  def boundary
    body.match(/; boundary="(.+?)"/)[1]
  end

  WORD_REPLACEMENTS = {
    8220.chr(Encoding::UTF_8) => '"', # “
    8221.chr(Encoding::UTF_8) => '"', # ”
    8216.chr(Encoding::UTF_8) => "'", # ‘
    8217.chr(Encoding::UTF_8) => "'", # ‘
    8211.chr(Encoding::UTF_8) => "-", # –
    8212.chr(Encoding::UTF_8) => "--", # —
    189.chr(Encoding::UTF_8) => "1/2", # ½
    188.chr(Encoding::UTF_8) => "1/4", # ¼
    190.chr(Encoding::UTF_8) => "3/4", # ¾
    169.chr(Encoding::UTF_8) => "(c)", # ©
    174.chr(Encoding::UTF_8) => "(R)", # ®
    8230.chr(Encoding::UTF_8) => '...' # …
  }

  def fix_word_chars!(string)
    WORD_REPLACEMENTS.each do |character, replacement|
      string.gsub!(/#{character}/, replacement)
    end
  end
end
