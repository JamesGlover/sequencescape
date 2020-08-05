# frozen_string_literal: true

# JSON API resource assumes that single table inheritance uses the default
# inheritance column, type. This looks like it may be fixed in 0.10.0
# This monkey patches the corresponding method to retrieve the type
# column directly.

# Tested in spec/requests/plates_spec.rb (Where we actually depend on this behaviour)

require 'jsonapi-resources'

unless JSONAPI::Resources::VERSION == '0.10.2'
  # We're being naughty. So lets ensure that anyone can easily find
  # our little hacks.
  Rails.logger.warn '*' * 80
  Rails.logger.warn "We are monkey patching 'jsonapi-resources' in #{__FILE__} "\
                    'but the gem version has changed since the patch was written.'\
                    'Please ensure that the patch is still required and compatible.'
  Rails.logger.warn '*' * 80
end
