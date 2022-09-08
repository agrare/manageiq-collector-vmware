require 'yaml'
require 'rbvmomi/vim'
require 'manageiq/providers/vmware/parser'
require 'manageiq/providers/vmware/miq_queue'
require 'manageiq/providers/vmware/collector/connection'
require 'manageiq/providers/vmware/collector/property_collector'

# see ManageIQ::Providers::Vmware::InfraManager::Inventory::Collector
module ManageIQ
  module Providers
    module Vmware
      class Collector
        include Connection
        include PropertyCollector

        def initialize(ems_id, hostname, port, user, password)
          @ems_id         = ems_id
          @hostname       = hostname
          @port           = port
          @user           = user
          @password       = password
          @counter        = 0
          @inventory_hash = Hash.new { |h, k| h[k] = {} }
        end

        def run
          # moved here to see how much time it took / if it hung
          puts "connecting to queue"
          @queue_client = ManageIQ::Providers::Vmware::ActiveMqClient.open(true, self.class.name)
          puts "connecting to queue - done"

          puts "connecting to ems"
          vim = connect(@hostname, @user, @password, @port)
          puts "connecting to ems - done (rev: #{vim.rev})"

          wait_for_updates(vim)
        ensure
          vim.serviceContent.sessionManager.Logout unless vim.nil?
          @queue_client&.close
        end

        private

        def publish_inventory(inventory)
          inventory.merge!(:counter => @counter += 1)

          ManageIQ::Providers::Vmware::MiqQueue.put_job(
            @queue_client,
            :message => inventory,
            :service => 'ems_inventory'
          )
        end

        def wait_for_updates(vim)
          puts "creating property filter"
          property_filter = create_property_filter(vim)
          puts "creating property filter - done"

          options = RbVmomi::VIM.WaitOptions(
            :maxObjectUpdates => 50,
            :maxWaitSeconds   => 10
          )

          version = ""
          while true
            start = Time.now
            update_set = vim.propertyCollector.WaitForUpdatesEx(:version => version, :options => options)
            finish = Time.now
            if update_set.nil?
              puts "No updates (#{finish - start})"
              next
            end

            version = update_set.version
            puts "update_set #{version || "ALL"}: #{update_set.filterSet.size} records (#{finish - start} seconds)"

            update_set.filterSet.to_a.each do |property_filter_update|
              if property_filter_update.nil?
                puts "empty properties update"
                next
              end

              object_updates = property_filter_update.objectSet.to_a
              if object_updates.empty?
                puts "no updates"
                next
              end
              start = Time.now
              puts "Processing #{object_updates.count} updates..."
              process_update_set(object_updates)
              finish = Time.now
              puts "Processing #{object_updates.count} updates...Complete (#{finish - start})"
            end
          end
        ensure
          property_filter.DestroyPropertyFilter unless property_filter.nil?
        end

        def process_update_set(object_updates)
          parser = ManageIQ::Providers::Vmware::Parser.new(@ems_id)

          object_updates.each do |object_update|
            object = object_update.obj
            kind   = object_update.kind

            props = case kind
                    when 'enter'
                      create_object(object, object_update.changeSet, object_update.missingSet)
                    when'modify'
                      update_object(object, object_update.changeSet, object_update.missingSet)
                    when 'leave'
                      delete_object(object)
                    end

            parser_method = "parse_#{object.class.wsdl_name.underscore}"
            parser.send(parser_method, object, props) if parser.respond_to?(parser_method)
          end

          publish_inventory(parser.inventory_raw)
        end

        DEFAULT_OBJECT_HASH = {
          "VirtualMachine" => {
            "config.template" => nil,
            "summary.config.name" => nil,
          },
          "Host"           => {
            "config.network.dnsConfig.hostName" => nil,
          },
          "Datastore"      => {
            "summary.name" => nil
          }
        }

        def create_object(object, change_set, missing_set)
          @inventory_hash[object.class.wsdl_name][object._ref] ||= DEFAULT_OBJECT_HASH[object.class.wsdl_name] || {}

          update_object(object, change_set, missing_set)
        end

        def update_object(object, change_set, _missing_set)
          props = @inventory_hash[object.class.wsdl_name][object._ref].dup

          change_set.to_a.each do |property_change|
            case property_change.op
            when 'add'
              props[property_change.name] ||= []
              props[property_change.name] << property_change.val
            when 'assign'
              props[property_change.name] = property_change.val
            when 'remove', 'indirectRemove'
              case props[property_change.name]
              when Array
                props.property_change.delete(property_change.val)
              when Hash
                props.except!(property_change.name)
              end
            end
          end

          @inventory_hash[object.class.wsdl_name][object._ref].each_key do |cached_key|
            if props.include? cached_key
              @inventory_hash[object.class.wsdl_name][object._ref][cached_key] = props[cached_key]
            end
          end

          props
        end

        def delete_object(object)
          @inventory_hash[object.class.wsdl_name].except!(object._ref)
          nil
        end
      end
    end
  end
end

