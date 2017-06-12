module ManageIQ
  module Providers
    module Vmware
      class Collector
        module InventoryCollections
          def initialize_inventory_collections
            @inventory_collections = {}

            defaults = {
              :manager_ref => [:ems_ref],
              :complete    => false,
              :targeted    => true,
              :saver_strategy => :concurrent_safe_batch,
              :unique_index_columns => [:ems_id, :ems_ref]
            }

            @inventory_collections[:vms] = ManageIQ::Providers::Inventory::InventoryCollection.new(
              defaults.merge(
                :model_class => "ManageIQ::Providers::Vmware::InfraManager::Vm",
                :association => :vms
              )
            )

            @inventory_collections[:templates] = ManageIQ::Providers::Inventory::InventoryCollection.new(
              defaults.merge(
                :model_class => "ManageIQ::Providers::Vmware::InfraManager::Template",
                :association => :miq_templates
              )
            )

            @inventory_collections[:hosts] = ManageIQ::Providers::Inventory::InventoryCollection.new(
              defaults.merge(
                :model_class => "ManageIQ::Providers::Vmware::InfraManager::Host",
                :association => :hosts
              )
            )

            @inventory_collections
          end
        end
      end
    end
  end
end
