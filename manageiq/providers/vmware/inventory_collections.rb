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

          collections[:storages] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            {:model_class => "Storage"}.merge(defaults)
          )

          collections
        end
      end
    end
  end
end
