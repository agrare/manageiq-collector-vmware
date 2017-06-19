require 'manageiq/providers/inventory'
require 'manageiq/providers/vmware/inventory_collections'

module ManageIQ
  module Providers
    module Vmware
      class Parser
        include InventoryCollections

        def initialize(ems_id)
          @ems_id      = ems_id
          @collections = initialize_inventory_collections
        end

        def inventory
          @collections
        end

        def inventory_yaml
          collections = inventory.map do |key, collection|
            next if collection.data.blank? && collection.manager_uuids.blank? && collection.all_manager_uuids.nil?

            {
              :name              => key,
              :manager_uuids     => collection.manager_uuids,
              :all_manager_uuids => collection.all_manager_uuids,
              :data              => collection.to_raw_data
            }
          end.compact

          inv = YAML.dump({
            :ems_id      => @ems_id,
            :class       => "ManageIQ::Providers::Vmware::Inventory::Persister::InfraManager::Streaming",
            :collections => collections
          })
        end

        def parse_compute_resource(cluster, props)
          return if props.nil?

          cluster_hash = {
            :ems_ref => cluster._ref,
            :name    => props["name"],
          }

          clusters.build cluster_hash
        end
        alias_method :parse_cluster_compute_resource, :parse_compute_resource

        def parse_datastore(datastore, props)
          return if props.nil?
        end

        def parse_distributed_virtual_portgroup(dvp, props)
        end

        def parse_distributed_virtual_switch(dvs, props)
        end
        alias_method :parse_vmware_distributed_virtual_switch, :parse_distributed_virtual_switch

        def parse_folder(folder, props)
        end
        alias_method :parse_datacenter, :parse_folder

        def parse_host_system(host, props)
          return if props.nil?

          hostname = props["config.network.dnsConfig.hostName"]

          host_hash = {
            :ems_ref   => host._ref,
            :name      => hostname,
            :hostname  => hostname,
          }

          hosts.build host_hash
        end

        def parse_resource_pool(rp, props)
          return if props.nil?
        end

        def parse_vapp(vapp, props)
        end

        def parse_virtual_machine(vm, props)
          return if props.nil? # TODO handle deletes

          vm_hash = {
            :ems_ref         => vm._ref,
            :vendor          => "vmware",
            :uid_ems         => props["summary.config.uuid"],
            :name            => props["summary.config.name"],
            :raw_power_state => props["summary.runtime.powerState"],
            :template        => props["summary.config.template"],
            :location        => props["summary.config.vmPathName"],
            :host            => lazy_find_host(props["summary.runtime.host"]),
          }

          collection = vm_hash[:template] ? templates : vms

          collection.build vm_hash
        end

        private

        def hosts
          @collections[:hosts]
        end

        def vms
          @collections[:vms]
        end

        def clusters
          @collections[:ems_clusters]
        end

        def templates
          @collections[:miq_templates]
        end

        def lazy_find_host(host)
          hosts.lazy_find(host._ref)
        end
      end
    end
  end
end
