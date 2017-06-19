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

          ds_hash = {
            :ems_ref => datastore._ref,
          }

          name               = props["summary.name"]
          store_type         = props["summary.type"].to_s.upcase
          total_space        = props["summary.capacity"]
          free_space         = props["summary.freeSpace"]
          uncommitted        = props["summary.uncommitted"]
          multiplehostaccess = props["summary.multipleHostAccess"]
          location           = props["summary.url"]

          ds_hash[:name]               = name               unless name.nil?
          ds_hash[:store_type]         = store_type         unless store_type.nil?
          ds_hash[:total_space]        = total_space        unless total_space.nil?
          ds_hash[:free_space]         = free_space         unless free_space.nil?
          ds_hash[:uncommitted]        = uncommitted        unless uncommitted.nil?
          ds_hash[:multiplehostaccess] = multiplehostaccess unless multiplehostaccess.nil?
          ds_hash[:location]           = location           unless location.nil?

          datastores.build ds_hash
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


          host_hash = {
            :ems_ref   => host._ref,
          }

          hostname         = props["config.network.dnsConfig.hostName"]
          ipaddress        = nil # TODO
          uid_ems          = nil # TODO
          product_name     = props["summary.config.product.name"]
          product_vendor   = props["summary.config.product.vendor"].split(",").first.to_s.downcase
          product_build    = props["summary.config.product.build"]
          connection_state = props["summary.runtime.connectionState"]
          maintenance_mode = props["summary.runtime.inMaintenanceMode"]
          power_state      = unless connection_state.nil? || maintenance_mode.nil?
                               if connection_state != "connected"
                                 "off"
                               elsif maintenance_mode.to_s.downcase == "true"
                                 "maintenance"
                               else
                                 "on"
                               end
                             end
          admin_disabled   = props["config.adminDisabled"].to_s.downcase == "true"
          asset_tag        = nil # TODO
          service_tag      = nil # TODO
          failover         = nil # TODO
          hyperthreading   = props["config.hyperThread.active"]

          host_hash[:name]             = hostname         unless hostname.nil?
          host_hash[:hostname]         = hostname         unless hostname.nil?
          host_hash[:ipaddress]        = ipaddress        unless ipaddress.nil?
          host_hash[:uid_ems]          = uid_ems          unless uid_ems.nil?
          host_hash[:vmm_vendor]       = product_vendor   unless product_vendor.nil?
          host_hash[:vmm_product]      = product_name     unless product_name.nil?
          host_hash[:vmm_buildnumber]  = product_build    unless product_build.nil?
          host_hash[:connection_state] = connection_state unless connection_state.nil?
          host_hash[:power_state]      = power_state      unless power_state.nil?
          host_hash[:admin_disabled]   = admin_disabled   unless admin_disabled.nil?
          host_hash[:maintenance]      = maintenance_mode unless maintenance_mode.nil?
          host_hash[:asset_tag]        = asset_tag        unless asset_tag.nil?
          host_hash[:service_tag]      = service_tag      unless service_tag.nil?
          host_hash[:failover]         = failover         unless failover.nil?
          host_hash[:hyperthreading]   = hyperthreading   unless hyperthreading.nil?

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

        def clusters
          @collections[:ems_clusters]
        end

        def datastores
          @collections[:storages]
        end

        def hosts
          @collections[:hosts]
        end

        def templates
          @collections[:miq_templates]
        end

        def vms
          @collections[:vms]
        end

        def lazy_find_host(host)
          hosts.lazy_find(host._ref)
        end
      end
    end
  end
end
