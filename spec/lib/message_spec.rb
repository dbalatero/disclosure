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

  describe '#thread_id' do
    it "should return a thread id" do
      expect(message.thread_id).to eq("5c73a357-4ace-4a53-b510-5973fb9baf81")
    end
  end

  describe '#in_reply_to' do
    it "should return In Reply To" do
      expect(message.in_reply_to).to eq(
        "<B9D26D72-3BC6-4CC1-BA99-CDC044AE7D95@kingcounty.gov>"
      )
    end
  end

  describe '#message_id' do
    it "should return message ID" do
      expect(message.message_id).to eq(
        "<864EAAC0BE31B84D92C9145C40A520F4AA98D327@MAILQDC3.kc.kingcounty.lcl>"
      )
    end
  end

  describe '#sender' do
    it "should return the sender" do
      expect(message.sender.name).to eq("Cortes, Katherine")
      expect(message.sender.email).to eq("katherine.cortes@kingcounty.gov")
    end
  end

  describe '#recipient' do
    it "should return the recipient" do
      expect(message.recipient.name).to eq("ZZGrp, Council Members")
      expect(message.recipient.email).to eq("zzcncmembers@kingcounty.gov")
    end
  end

  describe '#cc' do
    it "should return a list of CC'd people" do
      expect(message.cc.size).to eq(14)

      expect(message.cc[0].name).to eq("Domingo, Cindy")
      expect(message.cc[0].email).to eq("cindy.domingo@kingcounty.gov")
    end
  end
end
