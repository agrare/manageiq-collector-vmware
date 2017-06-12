require 'manageiq/providers/inventory'
require 'collector/connection'
require 'collector/inventory_collections'

module ManageIQ
  module Providers
    module Vmware
      class Collector
        include Connection
        include InventoryCollections

        def initialize(hostname, user, password)
          @hostname = hostname
          @user     = user
          @password = password
        end

        def run
          vim = connect(@hostname, @user, @password)
        ensure
          vim.serviceContent.sessionManager.Logout unless vim.nil?
        end
      end
    end
  end
end

