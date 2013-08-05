module JsConnect
  class SessionsController < ApplicationController
    def show
      @callback = params[:callback]
      @session = JsConnect.get_request_errors(params.except(:action, :controller))
      render 'show.js.erb'
    end
  end
end
