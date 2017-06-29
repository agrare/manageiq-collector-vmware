module ManageIQ
  module Providers
    module Vmware
      module InventoryCollections
        def initialize_inventory_collections
          collections = {}

          [
            [:vms_and_templates, "VmOrTemplate"],
            [:disks, "Disk"],
            [:networks, "Network"],
            [:guest_devices, "GuestDevice"],
            [:hardwares, "Hardware"],
            [:snapshots, "Snapshot"],
            [:operating_systems, "OperatingSystem"],
            [:custom_attributes, "CustomAttribute"],
            [:ems_folders, "EmsFolder"],
            [:resource_pools, "ResourcePool"],
            [:ems_clusters, "EmsCluster"],
            [:storages, "Storage"],
            [:hosts, "Host"],
            [:host_storages, "HostStorage"],
            [:switches, "Switch"],
            [:lans, "Lan"],
            [:storage_profiles, "StorageProfile"],
            [:customization_specs, "CustomizationSpec"],
          ].each do |assoc, model|
             collections[assoc] = ManageIQ::Providers::Inventory::InventoryCollection.new(:model_class => model)
             self.class.define_collection_method(assoc)
          end

          collections
        end
      end
    end
  end
end
