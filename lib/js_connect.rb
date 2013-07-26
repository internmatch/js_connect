require "js_connect/engine"

module JsConnect
  mattr_accessor :client_id, :secret

  def self.generate_signature
    raise ArgumentError.new
  end
end
