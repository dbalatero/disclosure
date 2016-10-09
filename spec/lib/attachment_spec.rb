require_relative '../../lib/attachment'

describe Attachment do
  let(:data) { "foo" }
  let(:attachment_file) { double(:attachment, filename: "haha.pdf", data: data) }
  subject(:attachment) { Attachment.new(attachment_file) }

  describe '#as_json' do
    it "should return the filename" do
      expect(attachment.as_json).to eq(
        filename: "haha.pdf"
      )
    end
  end

  describe '#valid?' do
    context 'attachment is a normal file' do
      it 'should return true' do
        expect(attachment.valid?).to be true
      end
    end

    context 'attachment is not a file' do
      let(:dirent_data) { Ole::Storage::Dirent.new(nil) }
      let(:dirent_attachment_file) { double(:attachment, data: dirent_data) }
      let(:dirent_attachment) { Attachment.new(dirent_attachment_file) }

      it "should return false" do
        expect(dirent_attachment.valid?).to be false
      end
    end
  end
end
