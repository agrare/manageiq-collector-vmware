module ManageIQ
  module Providers
    module Vmware
      class Parser
        module Host
          def parse_host_network(props)
            result = {}

            if props.include? "config.network.dnsConfig.hostName"
              result[:hostname] = props["config.network.dnsConfig.hostName"]
            end

            result
          end

          def parse_host_product(props)
            result = {}

            if props.include? "summary.config.product.name"
              result[:vmm_product] = props["summary.config.product.name"]
            end
            if props.include? "summary.config.product.vendor"
              result[:vmm_vendor] = props["summary.config.product.vendor"].split(",").first.to_s.downcase
            end
            if props.include? "summary.config.product.build"
              result[:vmm_buildnumber] = props["summary.config.product.build"]
            end

            result
          end

          def parse_host_runtime(props)
            result = {}

            if props.include? "summary.runtime.connectionState"
              result[:connection_state] = props["summary.runtime.connectionState"]
            end
            if props.include? "summary.runtime.inMaintenanceMode"
              result[:maintenance] = props["summary.runtime.inMaintenanceMode"]
            end

            if result.include?(:connection_state) && result.include?(:maintenance)
              result[:power_state] = if result[:connection_state] != "connected"
                                       "off"
                                     elsif result[:maintenance].to_s.downcase == "true"
                                       "maintenance"
                                     else
                                       "on"
                                     end
            end

            result
          end

          def parse_host_operating_systems(host, props)
          end

          def parse_host_hardware(host, props)
            result = {
              :host => host
            }

            if props.include? "summary.hardware.cpuMhz"
              result[:cpu_speed] = props["summary.hardware.cpuMhz"]
            end
            if props.include? "summary.hardware.cpuModel"
              result[:cpu_type] = props["summary.hardware.cpuModel"]
            end
            if props.include? "summary.hardware.vendor"
              result[:manufacturer] = props["summary.hardware.vendor"]
            end
            if props.include? "summary.hardware.model"
              result[:model] = props["summary.hardware.model"]
            end
            if props.include? "summary.hardware.numNics"
              result[:number_of_nics] = props["summary.hardware.numNics"]
            end
            if props.include? "summary.hardware.memorySize"
              result[:memory_mb] = props["summary.hardware.memorySize"].to_f / (1024 * 1024)
            end
            if props.include? "summary.hardware.numCpuPkgs"
              result[:cpu_sockets] = props["summary.hardware.numCpuPkgs"]
            end
            if props.include? "summary.hardware.numCpuCores"
              result[:cpu_total_cores] = props["summary.hardware.numCpuCores"]
            end
            if result.include?(:cpu_sockets) && result.include?(:cpu_total_cores)
              result[:cpu_cores_per_socket] = (result[:cpu_total_cores].to_f / result[:cpu_sockets].to_f).to_i
            end

            if props.include? "summary.config.product.name"
              result[:guest_os] = result[:guest_os_full_name] = props["config.product.name"].to_s.gsub(/^VMware\s*/i, "")
            end
            if props.include? "summary.config.vmotionEnabled"
              result[:vmotion_enabled] = props["config.vmotionEnabled"].to_s.downcase == "true"
            end

            if props.include? "summary.quickStats.overallCpuUsage"
              result[:cpu_usage] = props["summary.quickStats.overallCpuUsage"]
            end
            if props.include? "summary.quickStats.overallMemoryUsage"
              result[:memory_usage] = props["summary.quickStats.overallMemoryUsage"]
            end

            host_hardwares.build(result)
          end
        end
      end
    end
  end
end
