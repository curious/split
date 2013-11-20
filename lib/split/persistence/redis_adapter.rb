module Split
  module Persistence
    class RedisAdapter
      DEFAULT_CONFIG = {:namespace => 'persistence'}.freeze

      attr_reader :redis_key

      def initialize(context)
        if lookup_by = self.class.config[:lookup_by]
          if lookup_by.respond_to?(:call)
            key_frag = lookup_by.call(context)
          else
            key_frag = context.send(lookup_by)
          end
          @redis_key = redis_key_from_key_frag(key_frag)
        else
          raise "Please configure lookup_by"
        end
      end

      def [](field)
        Split.redis.hget(redis_key, field)
      end

      def []=(field, value)
        Split.redis.hset(redis_key, field, value)
      end

      def delete(field)
        Split.redis.hdel(redis_key, field)
      end

      def keys
        Split.redis.hkeys(redis_key)
      end

      def experiments
        Split.redis.hgetall(redis_key)
      end

      # Combine the current identity with a different identity (useful for when a user signs up and their id changes).
      # Note that this will preserve any existing values in the current identity, and will fully overwrite the values
      # in the other_identity, so that at the end the two match, with the current identity getting preference.
      def combine(other_identity)
        other_key = redis_key_from_key_frag(other_identity)
        other_hash = Split.redis.hgetall(other_key)
        # use hsetnx so that we don't clobber existing values
        other_hash.each { |test_name, test_value| Split.redis.hsetnx(redis_key, test_name, test_value) }
        # now rewrite the other_identity's tests to be identical to the current_identities one.
        Split.redis.del(other_key)
        Split.redis.hmset(other_key, self.experiments.to_a.flatten) unless self.experiments.empty?
      end

      def self.with_config(options={})
        self.config.merge!(options)
        self
      end

      def self.config
        @config ||= DEFAULT_CONFIG.dup
      end

      def self.reset_config!
        @config = DEFAULT_CONFIG.dup
      end

      private

      def redis_key_from_key_frag(key_frag)
        "#{self.class.config[:namespace]}:#{key_frag}"
      end

    end
  end
end
