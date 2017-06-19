module ManageIQ
  module Providers
    module Vmware
      module InventoryCollections
        def initialize_inventory_collections
          collections = {}

          collections[:vms] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ManageIQ::Providers::Vmware::InfraManager::Vm",
            :manager_ref => [:ems_ref],
            :complete    => false,
            :association => :vms
          )

          collections[:miq_templates] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ManageIQ::Providers::Vmware::InfraManager::Template",
            :manager_ref => [:ems_ref],
            :complete    => false,
            :association => :miq_templates
          )

          collections[:hosts] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "ManageIQ::Providers::Vmware::InfraManager::Host",
            :manager_ref => [:ems_ref],
            :complete    => false,
            :association => :hosts
          )

          collections[:datastores] = ManageIQ::Providers::Inventory::InventoryCollection.new(
            :model_class => "Storage",
            :manager_ref => [:ems_ref],
            :complete    => false,
            :association => :storages
          )

          collections
        end
      end
    end
  end
end
