require_relative '../../lib/attachment'

describe Attachment do
  let(:attachment_file) { double(:attachment, filename: "haha.pdf") }
  subject(:attachment) { Attachment.new(attachment_file) }

  describe '#as_json' do
    it "should return the filename" do
      expect(attachment.as_json).to eq(
        filename: "haha.pdf"
      )
    end
  end
end
