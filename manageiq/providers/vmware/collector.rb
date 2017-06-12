require 'rbvmomi/vim'

require 'manageiq/providers/inventory'
require 'manageiq/providers/vmware/collector/connection'
require 'manageiq/providers/vmware/collector/inventory_collections'
require 'manageiq/providers/vmware/collector/property_collector'

module ManageIQ
  module Providers
    module Vmware
      class Collector
        include Connection
        include InventoryCollections
        include PropertyCollector

        def initialize(hostname, user, password)
          @hostname = hostname
          @user     = user
          @password = password
        end

        def run
          vim = connect(@hostname, @user, @password)

          wait_for_updates(vim)
        ensure
          vim.serviceContent.sessionManager.Logout unless vim.nil?
        end

        private

        def wait_for_updates(vim)
          property_filter = create_property_filter(vim)

          options = RbVmomi::VIM.WaitOptions(:maxWaitSeconds => 10)

          version = ""
          while true
            update_set = vim.propertyCollector.WaitForUpdatesEx(:version => version, :options => options)
            next if update_set.nil?

            update_set.filterSet.to_a.each do |property_filter_update|
              next if property_filter_update.nil?

              object_updates = property_filter_update.objectSet.to_a
              next if object_updates.empty?

              puts "Processing #{object_updates.count} updates..."
              process_update_set(object_updates)
              puts "Processing #{object_updates.count} updates...Complete"
            end

            version = update_set.version
          end
        ensure
          property_filter.DestroyPropertyFilter unless property_filter.nil?
        end

        def process_update_set(object_updates)
          object_updates.each do |object_update|
            obj  = object_update.obj
            kind = object_update.kind

            puts "#{kind} #{obj.class.wsdl_name}:#{obj._ref}"
          end
        end

      end
    end
  end
end

