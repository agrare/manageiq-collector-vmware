require 'manageiq/providers/inventory'
require 'manageiq/providers/vmware/inventory_collections'
require 'manageiq/providers/vmware/parser/all'

module ManageIQ
  module Providers
    module Vmware
      class Parser
        include InventoryCollections
        include Parser::All

        def initialize(ems_id)
          @ems_id      = ems_id
          @collections = initialize_inventory_collections
        end

        def self.define_collection_method(collection_key)
          define_method(collection_key) { @collections[collection_key] }
        end

        def inventory
          @collections
        end

        def inventory_raw
          collections = inventory.map do |key, collection|
            next if collection.data.blank? && collection.manager_uuids.blank? && collection.all_manager_uuids.nil?

            {
              :name              => key,
              :manager_uuids     => collection.manager_uuids,
              :all_manager_uuids => collection.all_manager_uuids,
              :data              => collection.to_raw_data
            }
          end.compact

          {
            :ems_id      => @ems_id,
            :class       => "ManageIQ::Providers::Vmware::InfraManager::Inventory::Persister::Stream",
            :collections => collections
          }
        end

        def parse_compute_resource(cluster, props)
          ems_clusters.manager_uuids << cluster._ref
          return if props.nil?

          cluster_hash = {
            :ems_ref => cluster._ref,
          }

          cluster_hash[:name] = URI.decode(props["name"]) if props.include?("name")

          cluster_hash[:effective_cpu]    = props["summary.effectiveCpu"].to_i                    if props.include?("summary.effectiveCpu")
          cluster_hash[:effective_memory] = (props["summary.effectiveMemory"].to_i * 1024 * 1024) if props.include?("summary.effectiveMemory")

          cluster_hash[:ha_enabled]       = props["configuration.dasConfig.enabled"].to_s.downcase == "true" if props.include?("configuration.dasConfig.enabled")
          cluster_hash[:ha_admit_control] = props["configuration.dasConfig.admissionControlEnabled"]         if props.include?("configuration.dasConfig.admissionControlEnabled")
          cluster_hash[:ha_max_failures]  = props["configuration.dasConfig.failoverLevel"]                   if props.include?("configuration.dasConfig.failoverLevel")

          cluster_hash[:drs_enabled]             = props["configuration.drsConfig.enabled"].to_s.downcase == "true" if props.include?("configuration.drsConfig.enabled")
          cluster_hash[:drs_automation_level]    = props["configuration.drsConfig.defaultVmBehavior"]               if props.include?("configuration.drsConfig.defaultVmBehavior")
          cluster_hash[:drs_migration_threshold] = props["configuration.drsConfig.vmotionRate"]                     if props.include?("configuration.drsConfig.vmotionRate")

          ems_clusters.build(cluster_hash)
        end
        alias_method :parse_cluster_compute_resource, :parse_compute_resource

        def parse_datastore(datastore, props)
          storages.manager_uuids << datastore._ref
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

          storages.build(ds_hash)
        end

        def parse_distributed_virtual_portgroup(dvp, props)
        end

        def parse_distributed_virtual_switch(dvs, props)
        end
        alias_method :parse_vmware_distributed_virtual_switch, :parse_distributed_virtual_switch

        def parse_folder(folder, props)
          ems_folders.manager_uuids << folder._ref
          return if props.nil?

          type = case folder.class.wsdl_name
                 when "Folder"
                   "EmsFolder"
                 when "Datacenter"
                   "Datacenter"
                 else
                   raise "Invalid folder type #{folder.class.wsdl_name}"
                 end

          folder_hash = {
            :ems_ref => folder._ref,
            :uid_ems => folder._ref,
            :type    => type,
          }

          name = props["name"]
          folder_hash[:name] = URI.decode(name) unless name.nil?

          ems_folders.build(folder_hash)
        end
        alias_method :parse_datacenter, :parse_folder

        def parse_host_system(host, props)
          hosts.manager_uuids << host._ref
          return if props.nil?


          host_hash = {
            :ems_ref => host._ref,
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

          hosts.build(host_hash)
        end

        def parse_resource_pool(rp, props)
          resource_pools.manager_uuids << rp._ref
          return if props.nil?

          vapp = rp.class.wsdl_name == "VirtualApp"

          rp_hash = {
            :ems_ref => rp._ref,
            :uid_ems => rp._ref,
            :vapp    => vapp,
          }

          name = props["name"]

          rp_hash[:name] = URI.decode(name) unless name.nil?

          resource_pools.build(rp_hash)
        end
        alias_method :parse_vapp, :parse_resource_pool

        def parse_virtual_machine(vm, props)
          vms_and_templates.manager_uuids << vm._ref
          return if props.nil?

          vm_hash = {
            :ems_ref => vm._ref,
            :vendor  => "vmware",
          }

          uid_ems          = props["summary.config.uuid"]
          name             = props["summary.config.name"]
          raw_power_state  = props["summary.runtime.powerState"]
          location         = props["summary.config.vmPathName"]
          tools_status     = props["summary.guest.toolsStatus"]
          boot_time        = props["summary.runtime.bootTime"]
          standby_action   = props["config.defaultPowerOps.standbyAction"]
          connection_state = props["summary.runtime.connectionState"]
          affinity_set     = props["config.cpuAffinity.affinitySet"]
          cpu_affinity     = unless affinity_set.nil?
                               if affinity_set.kind_of? Array
                                 affinity_set.join(",")
                               else
                                 affinity_set.to_s
                               end
                             end
          template         = props["summary.config.template"]
          linked_clone     = nil
          fault_tolerance  = nil

          resource_config   = parse_virtual_machine_resource_config(props)

          host_ref          = props["summary.runtime.host"].try(:_ref)
          host              = hosts.lazy_find(host_ref) unless host_ref.nil?
          datastores        = props["datastore"].to_a.collect { |ds| storages.lazy_find(ds._ref) }.compact
          storage           = nil # TODO: requires datastore name cache
          custom_attributes = nil
          snapshots         = []

          hot_add           = parse_virtual_machine_hot_add(props)

          vm_hash[:uid_ems]          = uid_ems          unless uid_ems.nil?
          vm_hash[:name]             = name             unless name.nil?
          vm_hash[:raw_power_state]  = raw_power_state  unless raw_power_state.nil?
          vm_hash[:location]         = location         unless location.nil?
          vm_hash[:tools_status]     = tools_status     unless tools_status.nil?
          vm_hash[:template]         = template         unless template.nil?
          vm_hash[:boot_time]        = boot_time        unless boot_time.nil?
          vm_hash[:standby_action]   = standby_action   unless standby_action.nil?
          vm_hash[:connection_state] = connection_state unless connection_state.nil?
          vm_hash[:cpu_affinity]     = cpu_affinity     unless cpu_affinity.nil?

          vm_hash[:type] = "ManageIQ::Providers::Vmware::InfraManager::#{template ? "Template" : "Vm"}"

          vm_hash.merge!(resource_config)
          vm_hash.merge!(hot_add)

          vm_hash[:host] = host unless host.nil?

          vm = vms_and_templates.build(vm_hash)

          parse_virtual_machine_operating_system(vm, props)
          parse_virtual_machine_hardware(vm, props)
        end
      end
    end
  end
end
