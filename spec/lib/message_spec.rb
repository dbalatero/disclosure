require_relative '../../lib/message'

describe Message do
  subject(:message) { Message.new('spec/fixtures/test.msg') }

  describe '#subject' do
    it "should return a subject" do
      expect(message.subject).to eq("CFJC update: Project Labor Agreement & targeted local hire")
    end
  end

  describe '#plain_body' do
    it "should return the correct body" do
      expect(message.plain_body).to match(/^Hello Councilmembers:/)
    end
  end

  describe '#attachments' do
    it "should return a list of attachments" do
      expect(message.attachments.size).to eq(2)
    end
  end
end
