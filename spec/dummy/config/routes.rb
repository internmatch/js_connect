Rails.application.routes.draw do

  mount JsConnect::Engine => "/js_connect"
end
