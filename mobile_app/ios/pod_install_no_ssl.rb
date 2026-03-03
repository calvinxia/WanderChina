#!/usr/bin/env ruby

require 'net/http'
require 'openssl'

# Monkey patch Net::HTTP to disable SSL verification
module Net
  class HTTP
    alias_method :original_use_ssl=, :use_ssl=

    def use_ssl=(flag)
      self.original_use_ssl = flag
      self.verify_mode = OpenSSL::SSL::VERIFY_NONE if flag
    end
  end
end

# Now load and run CocoaPods
load Gem.bin_path('cocoapods', 'pod')
