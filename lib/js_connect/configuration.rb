module JsConnect
  class Configuration
    attr_accessor :client_id, :secret, :current_user, :blank_image_url

    def initialize
      @current_user = :current_user
      @blank_image_url = ''
    end

    def configured?
      self.client_id.present? && self.secret.present?
    end
  end
end
