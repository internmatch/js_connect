module JsConnect
  class Configuration
    attr_accessor :client_id, :secret, :current_user, :blank_image_url, :digest

    def initialize
      @current_user = :current_user
      @blank_image_url = ''
      @digest = Digest::MD5
    end

    def evaluate_current_user(context)
      if self.current_user.respond_to?(:call)
        self.current_user.call(context)
      else
        context.send(self.current_user)
      end
    end

    def hexdigest(str)
      @digest.hexdigest(str)
    end

    def configured?
      self.client_id.present? && self.secret.present?
    end

    def assert_configured!
      raise ArgumentError.new unless self.configured?
    end
  end
end
