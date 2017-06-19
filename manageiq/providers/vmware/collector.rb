require 'kafka'
require 'yaml'
require 'rbvmomi/vim'
require 'manageiq/providers/vmware/parser'
require 'manageiq/providers/vmware/collector/connection'
require 'manageiq/providers/vmware/collector/property_collector'

module ManageIQ
  module Providers
    module Vmware
      class Collector
        include Connection
        include PropertyCollector

        def initialize(ems_id, hostname, user, password)
          @ems_id         = ems_id
          @hostname       = hostname
          @user           = user
          @password       = password
          @inventory_hash = Hash.new { |h, k| h[k] = {} }
          @kafka          = Kafka.new(seed_brokers: ["localhost:9092"], client_id: "miq-collector")
        end

        def run
          vim = connect(@hostname, @user, @password)

          wait_for_updates(vim)
        ensure
          vim.serviceContent.sessionManager.Logout unless vim.nil?
        end

        private

        def kafka_inventory_producer
          @kafka.producer
        end

        def publish_inventory(stream, inventory)
          stream.produce(inventory, topic: "inventory")
          stream.deliver_messages
        end

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
          inventory_stream = kafka_inventory_producer
          parser = ManageIQ::Providers::Vmware::Parser.new(@ems_id)

          object_updates.each do |object_update|
            object = object_update.obj
            kind   = object_update.kind

            case kind
            when 'enter', 'modify'
              update_object(object, object_update.changeSet, object_update.missingSet)
            when 'leave'
            end

            props = @inventory_hash[object.class.wsdl_name][object._ref]

            parser_method = "parse_#{object.class.wsdl_name.underscore}"
            parser.send(parser_method, object, props) if parser.respond_to?(parser_method)
          end


          publish_inventory(inventory_stream, parser.inventory_yaml)
        end

        def update_object(object, change_set, _missing_set)
          props = @inventory_hash[object.class.wsdl_name][object._ref] ||= {}

          change_set.to_a.each do |property_change|
            case property_change.op
            when 'add'
            when 'assign'
              props[property_change.name] = property_change.val
            when 'remove', 'indirectRemove'
            end
          end
        end

        def delete_object(obj)
          @inventory_hash[object.class.wsdl_name].except!(object._ref)
        end
      end
    end
  end
end

