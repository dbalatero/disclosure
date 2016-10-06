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
end
