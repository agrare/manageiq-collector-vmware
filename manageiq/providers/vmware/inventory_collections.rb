module ManageIQ
  module Providers
    module Vmware
      module InventoryCollections
        def initialize_inventory_collections
          collections = {}

          defaults = {
            :manager_ref => [:ems_ref],
          }

          collections[:vms] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "ManageIQ::Providers::Vmware::InfraManager::Vm"}.merge(defaults)
          )

          collections[:ems_folders] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "EmsFolder"}.merge(defaults)
          )

          collections[:miq_templates] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "ManageIQ::Providers::Vmware::InfraManager::Template"}.merge(defaults)
          )

          collections[:hosts] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "ManageIQ::Providers::Vmware::InfraManager::Host"}.merge(defaults)
          )

          collections[:ems_clusters] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "EmsCluster"}.merge(defaults)
          )

          collections[:resource_pools] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "ResourcePool"}.merge(defaults)
          )

          collections[:storages] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "Storage"}.merge(defaults)
          )

          collections
        end

        def clusters
          @collections[:ems_clusters]
        end

        def datastores
          @collections[:storages]
        end

        def folders
          @collections[:ems_folders]
        end

        def hosts
          @collections[:hosts]
        end

        def resource_pools
          @collections[:resource_pools]
        end

        def templates
          @collections[:miq_templates]
        end

        def vms
          @collections[:vms]
        end

        def lazy_find_host(host)
          return nil if host.nil?
          hosts.lazy_find(host._ref)
        end

        def lazy_find_datastore(ds)
          return nil if ds.nil?
          datastores.lazy_find(ds._ref)
        end
      end
    end
  end
end
