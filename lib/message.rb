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

class Person
  EMAIL_REGEX = /<(.+?@.+?)>$/

  def initialize(line)
    @line = line.strip
  end

  def name
    return unless has_name?

    @name ||= line
      .match(/^(.+)\s+#{EMAIL_REGEX}/)[1]
      .gsub(/"/, '')
  end

  def email
    @email ||= (has_name? ? line.match(EMAIL_REGEX)[1] : line).downcase
  end

  private

  def line
    @line
  end

  def has_name?
    !!line.match(EMAIL_REGEX)
  end
end

class Message
  CC_LIST_REGEX = /
    (?:     # Begin non-capture group
    (?<=\") # Match a double-quote in a positive lookbehind
    .+?     # Match one or more characters lazily
    (?=\")  # Match a double quote in a positive lookahead
    )       # End non-capture group
    |       # Or
    \s\d+   # Match a whitespace character followed by one or more digits
    /x      # Extended mode

  attr_reader :path, :msg

  def initialize(path)
    @path = path
    @msg = Mapi::Msg.open(path)
  end

  def sender
    @sender ||= Person.new(msg.from)
  end

  def recipient
    @recipient ||= Person.new(msg.to)
  end

  def cc
    @cc ||= begin
      temp_comma_replacement = 9679.chr(Encoding::UTF_8)

      msg
        .cc
        .gsub(/(".+?),(.+?")/, "\\1#{temp_comma_replacement}\\2")
        .split(/,\s*/)
        .map { |line| Person.new(line.gsub(temp_comma_replacement, ',')) }
    end
  end

  def subject
    msg.subject
  end

  def headers
    msg.headers
  end

  def attachments
    @attachments ||= msg.attachments.map { |attachment| Attachment.new(attachment) }
  end

  def thread_id
    return @thread_id if defined?(@thread_id)

    index = headers['Thread-Index'].first
    return nil if index.nil?

    # Uh, see:
    #   http://www.meridiandiscovery.com/how-to/e-mail-conversation-index-metadata-computer-forensics/
    #   http://forum.rebex.net/3841/how-to-interprete-thread-index-header/
    #   https://stackoverflow.com/questions/31844321/how-to-convert-a-base64-encoded-string-to-uuid-format
    #   https://www.jwz.org/doc/threading.html
    @thread_id = index
      .unpack("m0")
      .first
      .unpack("A6H8H4H4H4H12")[1..-1]
      .join("-")
  end

  def message_id
    msg.headers['Message-ID'].first rescue nil
  end

  def in_reply_to
    msg.headers['In-Reply-To'].first rescue nil
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
