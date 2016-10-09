require 'mapi/msg'
require 'pry'
require_relative './attachment'
require_relative './person'

class Message
  attr_reader :msg

  def initialize(path_or_msg)
    if path_or_msg.is_a?(String)
      @msg = Mapi::Msg.open(path_or_msg)
    else
      @msg = path_or_msg
    end
  end

  def as_json
    # TODO do we need the HTML body as well?
    {
      sender: sender.as_json,
      recipient: recipient.as_json,
      sent_at: sent_at,
      cc: cc.map(&:as_json),
      subject: subject,
      headers: headers,
      attachments: attachments_without_emails.map(&:as_json),
      thread_id: thread_id,
      message_id: message_id,
      in_reply_to: in_reply_to,
      plain_body: plain_body
    }
  end

  def attachments_without_emails
    attachments.reject(&:outlook_message?)
  end

  def sender
    @sender ||= Person.new(msg.from)
  end

  def recipient
    @recipient ||= Person.new(msg.to)
  end

  def sent_at
    @sent_at ||= Time.parse(msg.headers["Date"].first) rescue nil
  end

  def cc
    @cc ||= begin
      if msg.cc.nil?
        []
      else
        temp_comma_replacement = 9679.chr(Encoding::UTF_8)

        msg
          .cc
          .gsub(/(".+?),(.+?")/, "\\1#{temp_comma_replacement}\\2")
          .split(/,\s*/)
          .map { |line| Person.new(line.gsub(temp_comma_replacement, ',')) }
      end
    end
  end

  def subject
    msg.subject
  end

  def headers
    msg.headers
  end

  def attachments
    @attachments ||= msg
      .attachments
      .map { |attachment| Attachment.new(attachment) }
      .select(&:valid?)
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
      plain = part_for('text/plain').body.dup

      plain.gsub!(/\r/, '')
      plain.gsub!(/\n\s+\n/, "\n\n")
      plain.gsub!(/\n{3,}/, "\n\n")

      fix_word_chars!(plain)
      plain.strip!

      plain
    end
  end

  private

  def part_for(type)
    msg.body_to_mime.parts.detect { |part| part.content_type == type }
  end

  CC_LIST_REGEX = /
    (?:     # Begin non-capture group
    (?<=\") # Match a double-quote in a positive lookbehind
    .+?     # Match one or more characters lazily
    (?=\")  # Match a double quote in a positive lookahead
    )       # End non-capture group
    |       # Or
    \s\d+   # Match a whitespace character followed by one or more digits
    /x      # Extended mode

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
