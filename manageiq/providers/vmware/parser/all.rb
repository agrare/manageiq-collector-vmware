require 'manageiq/providers/vmware/parser/virtual_machine'

module ManageIQ
  module Providers
    module Vmware
      class Parser
        module All
          include VirtualMachine
        end
      end
    end
  end
end
