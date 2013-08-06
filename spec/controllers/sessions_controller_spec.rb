require 'spec_helper'

describe JsConnect::SessionsController do
  routes { JsConnect::Engine.routes }
  let(:client_id) { '1234' }
  let(:secret) { '1234565432123456' }
  let(:timestamp) { Time.now.utc.to_i }
  let(:signature) { Digest::MD5.hexdigest(timestamp.to_s + secret) }
  let(:valid_params) {
    {
      :callback => 'callback', :clientid => client_id,
      :timestamp => timestamp, :signature => signature
    }
  }

  before do
    JsConnect.config do |c|
      c.client_id = client_id
      c.secret = secret
    end
  end

  context 'the request has errors' do
    before do
      JsConnect.config.current_user = proc { nil }
    end

    it 'returns an error jsonp when provided bad data' do
      get :show, :callback => 'callback'
      response.should be_success
      session = assigns(:session)
      session.error.should == 'invalid_request'
    end
  end

  context 'the user is not signed in to the site' do
    before do
      JsConnect.config.current_user = proc { nil }
    end

    it 'returns a non-user response' do
      get :show, valid_params
      response.should be_success
      session = assigns(:session)
      session['name'].should be_blank
      session['photourl'].should == JsConnect.config.blank_image_url
    end
  end
end
