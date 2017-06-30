module ManageIQ
  module Providers
    module Vmware
      class Parser
        module ResourcePool
          def parse_resource_pool_cpu_allocation(props)
            result = {}

            if props.include? "summary.config.memoryAllocation.reservation"
              result[:memory_reserve] = props["summary.config.memoryAllocation.reserve"]
            end
            if props.include? "summary.config.memoryAllocation.expandableReservation"
              result[:memory_reserve_expand] = props["summary.config.memoryAllocation.expandableReservation"].to_s.downcase == "true"
            end
            if props.include? "summary.config.memoryAllocation.limit"
              result[:memory_limit] = props["summary.config.memoryAllocation.limit"]
            end
            if props.include? "summary.config.memoryAllocation.shares.shares"
              result[:memory_shares] = props["summary.config.memoryAllocation.shares.shares"]
            end
            if props.include? "summary.config.memoryAllocation.shares.limit"
              result[:memory_limit] = props["summary.config.memoryAllocation.shares.limit"]
            end

            result
          end

          def parse_resource_pool_memory_allocation(props)
            result = {}

            if props.include? "summary.config.cpuAllocation.reservation"
              result[:cpu_reserve] = props["summary.config.cpuAllocation.reserve"]
            end
            if props.include? "summary.config.cpuAllocation.expandableReservation"
              result[:cpu_reserve_expand] = props["summary.config.cpuAllocation.expandableReservation"].to_s.downcase == "true"
            end
            if props.include? "summary.config.cpuAllocation.limit"
              result[:cpu_limit] = props["summary.config.cpuAllocation.limit"]
            end
            if props.include? "summary.config.cpuAllocation.shares.shares"
              result[:cpu_shares] = props["summary.config.cpuAllocation.shares.shares"]
            end
            if props.include? "summary.config.cpuAllocation.shares.limit"
              result[:cpu_limit] = props["summary.config.cpuAllocation.shares.limit"]
            end

            result
          end
        end
      end
    end
  end
end
