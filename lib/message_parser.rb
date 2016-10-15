class MessageParser
  def initialize(email_paths, **options)
    @email_paths = email_paths
    @options = options
    @parsed_emails = []
  end

  def self.parse!(*args)
    new(*args).parse!
  end

  def parse!
    input_emails.each_with_index do |email_path, i|
      puts "parsing email ##{i}"
      begin
        message = Message.new(email_path)
        handle_message(message)
      rescue Exception => e
        new_offset = options[:offset] + i
        puts "Error: unable to parse message at #{email_path}!"
        puts "use offset of #{new_offset} (-o #{new_offset}) to resume task after resolving this issue"

        write_json_file!

        raise
      end
    end

    write_json_file!
  end

  private

  attr_reader :email_paths, :options, :parsed_emails

  def input_emails
    email_paths[options[:offset] .. -1]
  end

  def write_json_file!
    # TODO group emails by thread id?
    print "writing #{parsed_emails.size} emails to #{options[:json_file]}..."

    File.open(options[:json_file], "wb") do |output_file|
      output_file.write(
        JSON.generate(
          emails: parsed_emails
        )
      )
    end

    puts "done"
  end

  def handle_message(message)
    # Write attachments out
    message.attachments.each do |attachment|
      # TODO handle duplicate clashing filenames, update attachment filename in output
      # JSON if needed

      if attachment.outlook_message?
        handle_message(attachment.to_message)
      else
        attachment.write_as_pdf_to_dir(options[:attachment_dir])
      end
    end

    parsed_emails << message.as_json
  end
end
