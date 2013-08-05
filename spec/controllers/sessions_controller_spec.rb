require 'spec_helper'

describe JsConnect::SessionsController do
  routes { JsConnect::Engine.routes }
  before do
    JsConnect.client_id = '1234'
    JsConnect.secret = '1234565432123456'
  end

  it 'returns an error jsonp when provided bad data' do
    get :show, :callback => 'callback'
    response.should be_success
    session = assigns(:session)
    session.error.should == 'invalid_request'
  end
end
