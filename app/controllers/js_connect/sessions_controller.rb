module JsConnect
  class SessionsController < ApplicationController
    def show
      @callback = params[:callback]
      @session = JsConnect.get_request_errors(params.except(:action, :controller))
      user = JsConnect.config.evaluate_current_user(self)
      @session ||= JsConnect.get_response(user, params.except(:action, :controller))
      render :text => %{#{@callback}(#{@session.to_json});}
    end
  end
end
