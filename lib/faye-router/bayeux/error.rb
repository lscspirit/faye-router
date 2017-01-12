module FayeRouter
  module Bayeux
    module Error
      ERROR_CODES = {
          :version_mismatch   => 300,
          :conn_type_mismatch => 301,
          :extension_mismatch => 302,
          :bad_request        => 400,
          :client_unknown     => 401,
          :parameter_missing  => 402,
          :channel_forbidden  => 403,
          :channel_unknown    => 404,
          :channel_invalid    => 405,
          :extension_unknown  => 406,
          :publish_failed     => 407,
          :server_error       => 500
      }

      # Creates an error message in Bayeux format
      #
      # @param error_sym [Symbol] error type (@see FayeRouter::Bayeux::Error::ERROR_CODES)
      # @param error_message [String] the error message
      # @param error_args [Array<String>] additional context information
      def bayeux_error(error_sym, error_message, *error_args)
        arg_string = error_args.compact.join(',')
        error_code = ERROR_CODES[error_sym] || 'xxx'

        [error_code, arg_string, error_message].join(':')
      end
    end
  end
end