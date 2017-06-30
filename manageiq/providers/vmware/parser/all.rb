require 'manageiq/providers/vmware/parser/cluster'
require 'manageiq/providers/vmware/parser/resource_pool'
require 'manageiq/providers/vmware/parser/virtual_machine'

module ManageIQ
  module Providers
    module Vmware
      class Parser
        module All
          include Cluster
          include ResourcePool
          include VirtualMachine
        end
      end
    end
  end
end
