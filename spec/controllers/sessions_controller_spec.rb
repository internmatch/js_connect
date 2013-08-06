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

  context 'the user is signed in' do
    let(:user) { Struct.new(:id, :name, :photo_url, :email, :roles).
                 new(123, 'Test User', 'http://www.google.com', 'test.user@gmail.com', ['member']) }
    before do
      JsConnect.config.current_user = proc { user }
    end

    context 'and the request hasn\'t been signed' do
      let(:params) { valid_params.except(:timestamp, :signature) }

      it 'responds with limited data' do
        get :show, params
        response.should be_success
        session = assigns(:session)
        session['name'].should == user.name
        session['photourl'].should == user.photo_url
      end
    end

    context 'and the request has been signed' do
      let(:response_signature) { 'jklasdfjklsdafkjhlasdfkjh' }
      before do
        JsConnect.stub(:generate_signature).with(anything){response_signature}
      end

      it 'responds with all the data' do
        get :show, valid_params
        response.should be_success
        session = assigns(:session)
        session['name'].should == user.name
        session['photourl'].should == user.photo_url
        session['uniqueid'].should == user.id
        session['email'].should == user.email
        session['roles'].should == user.roles.join(',')
        session['clientid'].should == client_id
        session['signature'].should == response_signature
      end
    end
  end
end
