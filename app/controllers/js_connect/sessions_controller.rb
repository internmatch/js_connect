module JsConnect
  class SessionsController < ApplicationController
    def show
      @callback = params[:callback]
      @session = JsConnect.get_request_errors(params.except(:action, :controller))
      user = JsConnect.config.current_user.respond_to?(:call) ? JsConnect.config.current_user.call(self) : send(JsConnect.config.current_user)
      @session = JsConnect.get_response(user, params.except(:action, :controller)) if @session.blank?
      render 'show.js.erb'
    end
  end
end
