require_relative '../../lib/attachment'

describe Attachment do
  let(:data) { double(filename: "haha.pdf", rewind: nil, read: 'string') }
  let(:attachment_file) { double(:attachment_file, filename: "haha.pdf", data: data) }
  subject(:attachment) { Attachment.new(attachment_file) }

  describe '#as_json' do
    it "should return the filename" do
      expect(attachment.as_json).to eq(
        filename: "b45cffe084dd3d20d928bee85e7b0f21-haha.pdf"
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
      let(:dirent_attachment_file) { double(:attachment_file, data: dirent_data, filename: "hoho.pdf") }
      let(:dirent_attachment) { Attachment.new(dirent_attachment_file) }

      it "should return false" do
        expect(dirent_attachment.valid?).to be false
      end
    end
  end
end
