module ManageIQ
  module Providers
    module Vmware
      class Parser
        module Host
          def parse_host_storages(host, props)
            return unless props.include? "datastore"

            props["datastore"].to_a.each do |datastore|
              result = {
                :host    => host,
                :storage => storages.lazy_find(datastore._ref),
                :ems_ref => datastore._ref,
              }

              datastore.host.to_a.detect { |mount| mount["key"] == host.data[:ems_ref] }

              host_storages.build(result)
            end
          end
        end
      end
    end
  end
end
