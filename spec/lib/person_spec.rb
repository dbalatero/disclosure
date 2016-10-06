require_relative '../../lib/person'

describe Person do
  subject(:person) { Person.new("David Balatero <Dbalatero@gmail.com>") }

  describe '#name' do
    it "should be the name" do
      expect(person.name).to eq('David Balatero')
    end

    it "should be nil if there's no name" do
      person = Person.new("dbalatero@gmail.com")
      expect(person.name).to be_nil
    end
  end

  describe '#email' do
    it "should be downcased" do
      expect(person.email).to eq('dbalatero@gmail.com')
    end
  end

  describe '#as_json' do
    it "should return JSON" do
      expect(person.as_json).to eq(
        name: "David Balatero",
        email: "dbalatero@gmail.com"
      )
    end
  end
end
