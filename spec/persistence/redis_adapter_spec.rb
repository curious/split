require "spec_helper"

describe Split::Persistence::RedisAdapter do

  let(:context) { double(:lookup => 'blah') }

  subject { Split::Persistence::RedisAdapter.new(context) }

  describe '#redis_key' do
    before { Split::Persistence::RedisAdapter.reset_config! }

    context 'default' do
      it 'should raise error with prompt to set lookup_by' do
        expect{Split::Persistence::RedisAdapter.new(context)
              }.to raise_error
      end
    end

    context 'config with lookup_by = proc { "block" }' do
      before { Split::Persistence::RedisAdapter.with_config(:lookup_by => proc{'block'}) }

      it 'should be "persistence:block"' do
        subject.redis_key.should == 'persistence:block'
      end
    end

    context 'config with lookup_by = proc { |context| context.test }' do
      before { Split::Persistence::RedisAdapter.with_config(:lookup_by => proc{'block'}) }
      let(:context) { double(:test => 'block') }

      it 'should be "persistence:block"' do
        subject.redis_key.should == 'persistence:block'
      end
    end

    context 'config with lookup_by = "method_name"' do
      before { Split::Persistence::RedisAdapter.with_config(:lookup_by => 'method_name') }
      let(:context) { double(:method_name => 'val') }

      it 'should be "persistence:bar"' do
        subject.redis_key.should == 'persistence:val'
      end
    end

    context 'config with namespace and lookup_by' do
      before { Split::Persistence::RedisAdapter.with_config(:lookup_by => proc{'frag'}, :namespace => 'namer') }

      it 'should be "namer"' do
        subject.redis_key.should == 'namer:frag'
      end
    end
  end

  context 'functional tests' do
    before { Split::Persistence::RedisAdapter.with_config(:lookup_by => 'lookup') }

    describe "#[] and #[]=" do
      it "should set and return the value for given key" do
        subject["my_key"] = "my_value"
        subject["my_key"].should eq("my_value")
      end
    end

    describe "#delete" do
      it "should delete the given key" do
        subject["my_key"] = "my_value"
        subject.delete("my_key")
        subject["my_key"].should be_nil
      end
    end

    describe "#keys" do
      it "should return an array of the user's stored keys" do
        subject["my_key"] = "my_value"
        subject["my_second_key"] = "my_second_value"
        subject.keys.should =~ ["my_key", "my_second_key"]
      end
    end

    describe "experiments" do
      it "should return a hash of the user's stored test name/value pairs" do
        subject["my_key"] = "my_value"
        subject.experiments.should == { "my_key" => "my_value" }
      end
    end

    describe "#combine" do
      let(:other) { Split::Persistence::RedisAdapter.new( double(:lookup => 'other') ) }

      it "should update the current identity with the other key/values" do
        other["my_key"] = "current_value"
        subject.combine('other')
        subject["my_key"].should == "current_value"
      end

      it "should preserve existing key/values in the current identity" do
        subject["my_key"] = "current_value"
        other["my_key"] = "other_value"
        subject.combine('other')
        subject["my_key"].should == "current_value"
      end

      it "should add existing key/values to the other identity" do
        subject["my_key"] = "current_value"
        subject.combine('other')
        other["my_key"].should == "current_value"
      end

      it "should overwrite key/values in the other identity" do
        subject["my_key"] = "current_value"
        other["my_key"] = "other_value"
        subject.combine('other')
        other["my_key"].should == "current_value"
      end

      it "should work when the current identity has no keys" do
        other["my_key"] = "current_value"
        subject.combine('other')
        subject["my_key"].should == "current_value"
      end

      it "should work when the other identity has no keys" do
        subject["my_key"] = "current_value"
        subject.combine('other')
        subject["my_key"].should == "current_value"
      end

      it "should work when neither identity has keys" do
        subject.combine('other')
        subject.experiments.should == {}
      end
    end

  end
end
