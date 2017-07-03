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

          summary    = parse_cluster_summary(props)
          das_config = parse_cluster_das_config(props)
          drs_config = parse_cluster_drs_config(props)

          cluster_hash.merge!(summary)
          cluster_hash.merge!(das_config)
          cluster_hash.merge!(drs_config)

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

          network = parse_host_network(props)
          product = parse_host_product(props)
          runtime = parse_host_runtime(props)

          uid_ems          = nil # TODO
          admin_disabled   = if props.include? "config.adminDisabled"
                               props["config.adminDisabled"].to_s.downcase == "true"
                             end
          asset_tag        = nil # TODO
          service_tag      = nil # TODO
          failover         = nil # TODO
          hyperthreading   = if props.include? "config.hyperThread.active"
                               props["config.hyperThread.active"]
                             end

          host_hash[:uid_ems]          = uid_ems          unless uid_ems.nil?
          host_hash[:admin_disabled]   = admin_disabled   unless admin_disabled.nil?
          host_hash[:asset_tag]        = asset_tag        unless asset_tag.nil?
          host_hash[:service_tag]      = service_tag      unless service_tag.nil?
          host_hash[:failover]         = failover         unless failover.nil?
          host_hash[:hyperthreading]   = hyperthreading   unless hyperthreading.nil?

          host_hash.merge!(network)
          host_hash.merge!(product)
          host_hash.merge!(runtime)
          host_hash[:name] = host_hash[:hostname] if host_hash.include? :hostname

          host = hosts.build(host_hash)

          parse_host_storages(host, props)
          parse_host_operating_systems(host, props)
          parse_host_hardware(host, props)
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

          rp_hash[:name] = URI.decode(props["name"]) if props.include? "name"

          cpu_allocation    = parse_resource_pool_cpu_allocation(props)
          memory_allocation = parse_resource_pool_memory_allocation(props)

          rp_hash.merge!(cpu_allocation)
          rp_hash.merge!(memory_allocation)

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
          linked_clone     = parse_virtual_machine_linked_clone(props)
          fault_tolerance  = parse_virtual_machine_fault_tolerance(props)

          resource_config  = parse_virtual_machine_resource_config(props)
          hot_add          = parse_virtual_machine_hot_add(props)
          host             = if props.include? "summary.runtime.host"
                               host_ref = props["summary.runtime.host"]._ref
                               hosts.lazy_find(host_ref)
                             end
          datastores       = props["datastore"].to_a.collect { |ds| storages.lazy_find(ds._ref) }.compact
          storage          = nil # TODO: requires datastore name cache
          snapshots        = []


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
          vm_hash[:linked_clone]     = linked_clone     unless linked_clone.nil?
          vm_hash[:fault_tolerance]  = fault_tolerance  unless fault_tolerance.nil?

          vm_hash[:type] = "ManageIQ::Providers::Vmware::InfraManager::#{template ? "Template" : "Vm"}"

          vm_hash.merge!(resource_config)
          vm_hash.merge!(hot_add)

          vm_hash[:host] = host unless host.nil?

          vm = vms_and_templates.build(vm_hash)

          parse_virtual_machine_operating_system(vm, props)
          parse_virtual_machine_hardware(vm, props)
          parse_virtual_machine_custom_attributes(vm, props)
        end
      end
    end
  end
end
