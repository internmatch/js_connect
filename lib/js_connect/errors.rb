module JsConnect
  module Errors
    class Base
      attr_reader :error, :message
      def initialize(error, message)
        @error, @message = error, message
      end

      def to_hash
        {'error' => self.error, 'message' => self.message}
      end

      def to_json(*)
        self.to_hash.to_json
      end

      def inspect
        "<#{self.class.name} #{self.to_hash.inspect}>"
      end
    end

    class InvalidRequest < Base
      def initialize(message)
        super('invalid_request', message)
      end
    end
    class ClientIdMissing < InvalidRequest
      def initialize
        super('The client_id parameter is missing.')
      end
    end
    class TimestampInvalid < InvalidRequest
      def initialize
        super('The timestamp is missing or invalid.')
      end
    end
    class SignatureMissing < InvalidRequest
      def initialize
        super('The signature is missing.')
      end
    end
    class InvalidClient < Base
      def initialize(client_id)
        super('invalid_client', "Unknown client #{client_id}.")
      end
    end
    class AccessDenied < Base
      def initialize
        super('access_denied', 'Signature invalid.')
      end
    end
  end
end
