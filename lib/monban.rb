require 'warden'
require "monban/version"
require "monban/configuration"
require "monban/services"
require "monban/controller_helpers"
require "monban/railtie"
require "monban/back_door"
require "monban/warden_setup"
require "monban/field_map"
require "monban/strategies/password_strategy"
require "active_support/core_ext/module/attribute_accessors"

# Monban is an authentication toolkit designed to allow developers create their own
# authentication solutions. If you're interested in a default implementation try {http://github.com/halogenandtoast/monban-generators Monban Generators}
module Monban
  mattr_accessor :warden_config
  mattr_accessor :config

  module Test
    autoload :Helpers, "monban/test/helpers"
    autoload :ControllerHelpers, "monban/test/controller_helpers"
  end

  # initialize Monban. Sets up warden and the default configuration.
  def self.initialize warden_config, &block
    setup_config(&block)
    setup_warden_config(warden_config)
  end

  # compares the token (password) to a digest
  #
  # @see Monban::Configuration#default_token_comparison
  def self.compare_token(digest, token)
    config.token_comparison.call(digest, token)
  end

  # hashes a token
  #
  # @see Monban::Configuration#default_hashing_method
  def self.hash_token(token)
    config.hashing_method.call(token)
  end

  def self.user_class
    config.user_class
  end

  def self.lookup(params, field_map)
    fields = FieldMap.new(params, field_map).to_fields
    self.config.find_method.call(fields)
  end

  # Puts monban into test mode. This will disable hashing passwords
  def self.test_mode!
    Warden.test_mode!
    self.config ||= Monban::Configuration.new
    config.hashing_method = ->(password) { password }
    config.token_comparison = ->(digest, undigested_password) do
      digest == undigested_password
    end
  end

  def self.configure(&block)
    self.config ||= Monban::Configuration.new
    yield self.config
  end

  # Resets monban in between tests.
  def self.test_reset!
    Warden.test_reset!
  end

  private

  def self.setup_config
    self.config ||= Monban::Configuration.new
    if block_given?
      yield config
    end
  end

  def self.setup_warden_config(warden_config)
    warden_config.failure_app = self.config.failure_app
    self.warden_config = warden_config
  end
end
