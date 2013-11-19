module Split
  module Persistence
    class SessionAdapter

      def initialize(context)
        @session = context.session
        @session[:split] ||= {}
      end

      def [](key)
        @session[:split][key]
      end

      def []=(key, value)
        @session[:split][key] = value
      end

      def delete(key)
        @session[:split].delete(key)
      end

      def keys
        @session[:split].keys
      end

      def experiments
        @session[:split]
      end

      # This is a no-op, since you only have access to one session.
      # Just included for consistency with the redis adapter
      def combine(other_identity)
      end

    end
  end
end