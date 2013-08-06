require "js_connect/engine"
require "js_connect/configuration"
require "js_connect/errors"

module JsConnect
  def self.get_request_errors(data)
    raise ArgumentError.new unless self.config.configured?
    return Errors::ClientIdMissing.new unless data.has_key?('clientid')
    return Errors::InvalidClient.new(data['clientid']) unless data['clientid'] == self.config.client_id
    return Errors::TimestampInvalid.new if !data.has_key?('timestamp') && data.has_key?('signature')
    return Errors::SignatureMissing.new if !data.has_key?('signature') && data.has_key?('timestamp')
    return Errors::TimestampInvalid.new if data.has_key?('timestamp') && data.has_key?('signature') && (Time.now.utc.to_i - data['timestamp'].to_i).abs > 1800
    return Errors::AccessDenied.new if data.has_key?('timestamp') && data.has_key?('signature') && data['signature'] != Digest::MD5.hexdigest("#{data['timestamp']}#{self.config.secret}")
  end

  def self.get_response(user, data)
    return {'name' => '', 'photourl' => self.config.blank_image_url} if user.nil?
    response = {'name' => user.name, 'photourl' => user.photo_url}
    if self.secure_request?(data)
      self.sign_data(response.merge(
        'uniqueid' => user.id,
        'email' => user.email,
        'roles' => user.roles.join(',')
      ))
    else
      response
    end
  end

  def self.secure_request?(data)
    data.has_key?('timestamp') && data.has_key?('signature')
  end

  def self.sign_data(data)
    raise ArgumentError.new unless self.config.configured?
    data.merge(
      'clientid' => self.config.client_id,
      'signature' => self.generate_signature(data)
    )
  end

  def self.generate_signature(data)
    raise ArgumentError.new unless self.config.configured?
    Digest::MD5.hexdigest("#{self.hash_to_sorted_params(data)}#{self.config.secret}") # MD5?!? Really!?!?!
  end

  def self.hash_to_sorted_params(data)
    data.sort_by(&:first).map do |value|
      "#{CGI.escape(value.first.to_s)}=#{CGI.escape(value.last)}"
    end.join("&")
  end

  def self.configuration
    @configuration ||= Configuration.new
    block_given? ? yield(@configuration) : @configuration
  end
  class << self
    alias_method :config, :configuration
  end
end
