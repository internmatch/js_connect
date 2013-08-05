JsConnect::Engine.routes.draw do
  resource :sessions, :only => [:show]
end
