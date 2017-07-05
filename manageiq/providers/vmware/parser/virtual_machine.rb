module ManageIQ
  module Providers
    module Vmware
      class Parser
        module VirtualMachine
          def parse_virtual_machine_linked_clone(props)
            return unless props.include?("summary.storage.unshared") && props.include?("summary.storage.committed")

            unshared  = props["summary.storage.unshared"]
            committed = props["summary.storage.committed"]
            ft_info   = props["summary.config.ftInfo.instanceUuids"].to_a

            return unshared != committed && ft_info.size <= 1
          end

          def parse_virtual_machine_fault_tolerance(props)
            return unless props.include?("summary.storage.unshared") && props.include?("summary.storage.committed")

            unshared  = props["summary.storage.unshared"]
            committed = props["summary.storage.committed"]
            ft_info   = props["summary.config.ftInfo.instanceUuids"].to_a

            return unshared != committed && ft_info.size > 1
          end

          def parse_virtual_machine_resource_config(props)
            result = {}

            result.merge!(parse_virtual_machine_resource_config_memory_allocation(props))
            result.merge!(parse_virtual_machine_resource_config_cpu_allocation(props))

            result
          end

          def parse_virtual_machine_resource_config_memory_allocation(props)
            result = {}

            memory_reserve        = props["resourceConfig.memoryAllocation.reservation"]
            memory_reserve_expand = props["resourceConfig.memoryAllocation.expandableReservation"]
            memory_limit          = props["resourceConfig.memoryAllocation.limit"]
            memory_shares         = props["resourceConfig.memoryAllocation.shares.shares"]
            memory_shares_level   = props["resourceConfig.memoryAllocation.shares.level"]

            result[:memory_reserve]        = memory_reserve        unless memory_reserve.nil?
            result[:memory_reserve_expand] = memory_reserve_expand unless memory_reserve_expand.nil?
            result[:memory_limit]          = memory_limit          unless memory_limit.nil?
            result[:memory_shares]         = memory_shares         unless memory_shares.nil?
            result[:memory_shares_level]   = memory_shares_level   unless memory_shares_level.nil?

            result
          end

          def parse_virtual_machine_resource_config_cpu_allocation(props)
            result = {}

            cpu_reserve        = props["resourceConfig.cpuAllocation.reservation"]
            cpu_reserve_expand = props["resourceConfig.cpuAllocation.expandableReservation"]
            cpu_limit          = props["resourceConfig.cpuAllocation.limit"]
            cpu_shares         = props["resourceConfig.cpuAllocation.shares.shares"]
            cpu_shares_level   = props["resourceConfig.cpuAllocation.shares.limit"]

            result[:cpu_reserve]        = cpu_reserve        unless cpu_reserve.nil?
            result[:cpu_reserve_expand] = cpu_reserve_expand unless cpu_reserve_expand.nil?
            result[:cpu_limit]          = cpu_limit          unless cpu_limit.nil?
            result[:cpu_shares]         = cpu_shares         unless cpu_shares.nil?
            result[:cpu_shares_level]   = cpu_shares_level   unless cpu_shares_level.nil?

            result
          end

          def parse_virtual_machine_hot_add(props)
            result = {}

            cpu_hot_add_enabled       = props["config.cpuHotAddEnabled"]
            cpu_hot_remove_enabled    = props["config.cpuHotRemoveEnabled"]
            memory_hot_add_enabled    = props["config.memoryHotAddEnabled"]
            memory_hot_add_limit      = props["config.hotPlugMemoryLimit"]
            memory_hot_add_increment  = props["config.hotPlugMemoryIncrementSize"]

            result
          end

          def parse_virtual_machine_operating_system(vm, props)
            return unless props.include? "summary.config.guestFullName"

            product_name = if props["summary.config.guestFullName"].blank?
                             "Other"
                           else
                             props["summary.config.guestFullName"]
                           end

            result = {
              :vm_or_template => vm,
              :product_name   => product_name
            }

            operating_systems.build(result)
          end

          def parse_virtual_machine_hardware(vm, props)
            result = {
              :vm_or_template => vm,
            }

            if props.include? "summary.config.uuid"
              result[:bios] = props["summary.config.uuid"]
            end

            if props.include? "summary.config.annotation"
              result[:annotation] = props["summary.config.annotation"]
            end

            if props.include? "summary.config.memorySizeMB"
              result[:memory_mb] = props["summary.config.memorySizeMB"]
            end

            if props.include? "config.version"
              result[:virtual_hw_version] = props["config.version"].to_s.split('-').last
            end

            result.merge!(parse_virtual_machine_guest_os(props))
            result.merge!(parse_virtual_machine_cpus(props))

            hardware = hardwares.build(result)

            parse_virtual_machine_disks(hardware, props)
          end

          def parse_virtual_machine_guest_os(props)
            result = {}

            guest_os = if props.include? "summary.config.guestId"
              if props["summary.config.guestId"].blank?
                "Other"
              else
                props["summary.config.guestId"].to_s.downcase.chomp("guest")
              end
            end

            guest_os_full_name = if props.include? "summary.config.guestFullName"
              if props["summary.config.guestFullName"].blank?
                "Other"
              else
                props["summary.config.guestFullName"]
              end
            end

            result[:guest_os]           = guest_os unless guest_os.nil?
            result[:guest_os_full_name] = guest_os_full_name unless guest_os_full_name.nil?

            result
          end

          def parse_virtual_machine_cpus(props)
            result = {}

            if props.include? "summary.config.numCpu"
              result[:cpu_total_cores] = props["summary.config.numCpu"].to_i
              if props.include? "config.hardware.numCoresPerSocket"
                result[:cpu_cores_per_socket] = props["config.hardware.numCoresPerSocket"].to_i
              end

              result[:cpu_cores_per_socket] = 1 if result[:cpu_cores_per_socket].to_i == 0
              result[:cpu_sockets]          = result[:cpu_total_cores] / result[:cpu_cores_per_socket]
            end

            result
          end

          def parse_virtual_machine_disks(hardware, props)
            return unless props.include?("config.hardware.device")
          end

          def parse_virtual_machine_custom_attributes(vm, props)
            custom_values = props["summary.customValue"].to_a
            return if custom_values.empty?

            key_to_name = {}
            props["availableField"].to_a.each { |af| key_to_name[af["key"]] = af["name"] }

            custom_values.each do |cv|
              custom_attributes.build(
                :resource => vm,
                :section  => "custom_field",
                :name     => key_to_name[cv["key"]],
                :value    => cv["value"],
                :source   => "VC"
              )
            end
          end
        end
      end
    end
  end
end
