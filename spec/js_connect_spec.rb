require 'spec_helper'

describe JsConnect do
  let(:client_id) { '12345' }
  let(:secret) { 'cf93f9688844e9249ce2cfde1c645a78' }
  before do
    JsConnect.client_id = client_id
    JsConnect.secret = secret
  end

  describe '#generate_signature' do
    it "raises argument error if there is no client_id configured" do
      JsConnect.client_id = nil
      expect {
        JsConnect.generate_signature
      }.to raise_exception(ArgumentError)
    end
  end
end
