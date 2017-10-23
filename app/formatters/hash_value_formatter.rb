
#
# Class HashFormatter provides a means of passing hashes
# through to objects, not ActionParameters
# Caution! It results in an unsafe hash. Use sparingly.
#
# @author Genome Research Ltd.
#
class HashValueFormatter < JSONAPI::ValueFormatter
  class << self
    def unformat(raw_value)
      raw_value.to_unsafe_hash
    end
  end
end
