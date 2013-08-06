require 'spec_helper'

describe JsConnect do
  let(:client_id) { '12345' }
  let(:secret) { 'cf93f9688844e9249ce2cfde1c645a78' }
  before do
    JsConnect.config do |c|
      c.client_id = client_id
      c.secret = secret
    end
  end

  shared_examples_for "it requires authentication information" do
    it "raises an argument error if there is no client_id configured" do
      JsConnect.config.client_id = nil
      expect {
        JsConnect.send(*method_and_args)
      }.to raise_exception(ArgumentError)
    end

    it "raises an argument error if there is no secret configured" do
      JsConnect.config.secret = nil
      expect {
        JsConnect.send(*method_and_args)
      }.to raise_exception(ArgumentError)
    end
  end

  describe '.generate_signature' do
    let(:data) { {'name' => "Ryan", 'photourl' => 'http://www.google.com'} }
    before do
      JsConnect.stub(:hash_to_sorted_params).with(data){ "name=Ryan&photourl=http%3A%2F%2Fwww.google.com" }
    end

    it_behaves_like "it requires authentication information" do
      let(:method_and_args) { [:generate_signature, data] }
    end

    it "returns the signature for the given hash" do
      JsConnect.generate_signature(data).should == 'f293c23fb5da1d66fde431d922ec694c'
    end
  end

  describe '.valid_request_signature?' do
    let(:data) { {'timestamp' => 12345678, 'signature' => '1234jkljklkjlklk'} }
    it_behaves_like "it requires authentication information" do
      let(:method_and_args) { [:valid_request_signature?, data] }
    end

    it 'returns true with the signature matches the hash' do
      Digest::MD5.stub(:hexdigest).with("#{data['timestamp']}#{secret}"){data['signature']}
      JsConnect.valid_request_signature?(data).should be_true
    end

    it 'returns true if the timestamp and signature are left off' do
      JsConnect.valid_request_signature?({}).should be_true
    end

    it 'returns false with the signature not matching the hash' do
      Digest::MD5.stub(:hexdigest).with("#{data['timestamp']}#{secret}"){'sadfsdsadfasdfas'}
      JsConnect.valid_request_signature?(data).should be_false
    end
  end

  describe '.valid_timestamp?' do
    let(:data) { {'timestamp' => Time.now.utc.to_i, 'signature' => '1234jkljklkjlklk'} }
    it_behaves_like "it requires authentication information" do
      let(:method_and_args) { [:valid_timestamp?, data] }
    end

    it 'returns true with the timestamp being recent' do
      JsConnect.valid_timestamp?(data).should be_true
    end

    it 'returns true if the timestamp and signature are left off' do
      JsConnect.valid_timestamp?({}).should be_true
    end

    it 'returns false with the timestamp being old' do
      JsConnect.valid_timestamp?(data.merge('timestamp' => 3.hours.ago.utc.to_i)).should be_false
    end
  end

  describe ".hash_to_sorted_params" do
    it "outputs the hash as CGI params" do
      JsConnect.hash_to_sorted_params({'test' => 'hi', 'so' => 'this is cool'}).should == 'so=this+is+cool&test=hi'
    end

    it "sorts the hash before turning in to parameters" do
      data = {'a' => 'a', 'g' => 'g', 'c' => 'c', 'd' => 'd', 'b' => 'b', 'f' => 'f', 'e' => 'e'}
      JsConnect.hash_to_sorted_params(data).should == "a=a&b=b&c=c&d=d&e=e&f=f&g=g"
    end
  end

  describe ".sign_data" do
    let(:data) { {'name' => "Ryan", 'photourl' => 'http://www.google.com'} }

    it_behaves_like "it requires authentication information" do
      let(:method_and_args) { [:sign_data, data] }
    end

    it "adds the client_id to the data" do
      JsConnect.sign_data(data)['client_id'].should == client_id
    end

    it "adds the generated signature to the data" do
      signature = "1234567"
      JsConnect.stub(:generate_signature).with(data){signature}

      JsConnect.sign_data(data)['signature'].should == signature
    end
  end

  describe ".secure_request?" do
    let(:timestamp) { Time.now.utc.to_i }
    let(:signature) { Digest::MD5.hexdigest(timestamp.to_s + secret) }
    let(:valid_data) { {'timestamp' => timestamp, 'signature' => signature} }

    it "returns true for a valid data" do
      JsConnect.secure_request?(valid_data).should be_true
    end

    it "returns false for an unsigned data" do
      JsConnect.secure_request?(valid_data.except('timestamp', 'signature')).should be_false
    end
  end

  describe ".insecure_request?" do
    let(:timestamp) { Time.now.utc.to_i }
    let(:signature) { Digest::MD5.hexdigest(timestamp.to_s + secret) }
    let(:valid_data) { {'timestamp' => timestamp, 'signature' => signature} }

    it "returns true for a insecure data" do
      JsConnect.insecure_request?(valid_data.except('timestamp', 'signature')).should be_true
    end

    it "returns false for an secure data" do
      JsConnect.insecure_request?(valid_data).should be_false
    end

    it "returns false for not-really either" do
      JsConnect.insecure_request?(valid_data.except('timestamp')).should be_false
    end
  end

  describe ".get_request_errors" do
    let(:timestamp) { Time.now.utc.to_i }
    let(:signature) { Digest::MD5.hexdigest(timestamp.to_s + secret) }
    let(:valid_data) {
      {
        'name' => "Ryan", 'photourl' => 'http://www.google.com',
        'client_id' => client_id, 'timestamp' => timestamp,
        'signature' => signature
      }
    }

    it_behaves_like "it requires authentication information" do
      let(:method_and_args) { [:get_request_errors, valid_data] }
    end

    it "returns an InvalidRequest if the client_id is missing" do
      JsConnect.get_request_errors(valid_data.except('client_id')).should be_instance_of(JsConnect::Errors::ClientIdMissing)
    end

    it "returns an InvalidRequest if the timestamp is missing but the signature is still there" do
      JsConnect.get_request_errors(valid_data.except('timestamp')).should be_instance_of(JsConnect::Errors::TimestampInvalid)
    end

    it "returns InvalidRequest if the timestamp is more than +/-30 minutes" do
      JsConnect.stub(:valid_timestamp?).with(anything){false}

      JsConnect.get_request_errors(valid_data).should be_instance_of(JsConnect::Errors::TimestampInvalid)
    end

    it "returns an InvalidRequest if the signature is missing but the timestamp is still there" do
      JsConnect.get_request_errors(valid_data.except('signature')).should be_instance_of(JsConnect::Errors::SignatureMissing)
    end

    it "returns an InvalidClient if the clientid doesn't match the configured client_id" do
      data = valid_data.merge("client_id" => '4321')
      JsConnect.get_request_errors(data).should be_instance_of(JsConnect::Errors::InvalidClient)
    end

    it "returns an AccessDenied if the signature is wrong" do
      JsConnect.stub(:valid_request_signature?).with(anything){false}
      JsConnect.get_request_errors(valid_data).should be_instance_of(JsConnect::Errors::AccessDenied)
    end

    it "returns nil when timestamp and signature are correct" do
      JsConnect.get_request_errors(valid_data).should be_nil
    end

    it "returns nil when timestamp and signature are completely gone" do
      JsConnect.get_request_errors(valid_data.except('timestamp', 'signature')).should be_nil
    end
  end
end
