require 'fileutils'
require 'json'

describe "disclosure binary" do
  let(:root_dir) { File.join(File.dirname(__FILE__), "..", "..") }
  let(:tmp_dir) { File.join(root_dir, "tmp") }
  let(:attachment_dir) { File.join(tmp_dir, "attachments") }
  let(:email_dir) { File.join(root_dir, "spec", "fixtures") }
  let(:output_json) { File.join(tmp_dir, "emails.json") }

  before do
    FileUtils.mkdir(attachment_dir)
  end

  after do
    FileUtils.rm_rf(attachment_dir)
    FileUtils.rm_rf(output_json)
  end

  def disclosure(input_dir, output_json, attachment_dir)
    opts = [
      "--input '#{input_dir}'",
      "--json '#{output_json}'",
      "--attachments '#{attachment_dir}'"
    ]

    `#{root_dir}/bin/disclosure #{opts.join(' ')}`
  end

  it "should dump a final JSON file to the output" do
    disclosure(email_dir, output_json, attachment_dir)

    json = JSON.parse(File.read(output_json))
    emails = json['emails']

    expect(emails.size).to eq(2)

    expect(emails[0]['subject']).to eq(
      "CFJC update: Project Labor Agreement & targeted local hire"
    )

    expect(emails[1]['subject']).to eq(
      "CFJC update - Alder Academy negotiations "
    )
  end

  context "failure" do
    let(:garbage_path) { File.join(email_dir, "zz-garbage.msg") }

    before do
      File.open(garbage_path, "wb") { |f| f.write "garbage all garbage" }
    end

    after do
      FileUtils.rm(garbage_path)
    end

    it "stops parsing" do
      result = disclosure(email_dir, output_json, attachment_dir)

      expect(result).to match(/Error: unable to parse message/)
      expect(result).to match(/zz-garbage\.msg!/)
      expect(result).to match(/use offset of 2 \(-o 2\)/)

      emails = JSON.parse(File.read(output_json))['emails']

      expect(emails.size).to eq(2)

      expect(emails[0]['subject']).to eq(
        "CFJC update: Project Labor Agreement & targeted local hire"
      )

      expect(emails[1]['subject']).to eq(
        "CFJC update - Alder Academy negotiations "
      )
    end
  end
end
