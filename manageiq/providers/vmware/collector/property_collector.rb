require 'manageiq/providers/vmware/collector/prop_set'

module ManageIQ
  module Providers
    module Vmware
      class Collector
        module PropertyCollector
          include PropSet

          def create_property_filter(vim)
            root_folder = vim.serviceContent.rootFolder

            root_folder_object_spec = RbVmomi::VIM.ObjectSpec(
              :obj => root_folder, :selectSet => select_set
            )

            spec = RbVmomi::VIM.PropertyFilterSpec(
              :objectSet => [root_folder_object_spec],
              :propSet   => prop_set
            )

            vim.propertyCollector.CreateFilter(:spec => spec, :partialUpdates => true)
          end

          def prop_set
            EmsRefreshPropMap.collect { |type, props| RbVmomi::VIM.PropertySpec(:type => type, :all => props.nil?, :pathSet => props) }
          end

          ALL_FOLDERS = %w[tsFolder tsDcToDsFolder tsDcToHostFolder tsDcToNetworkFolder
                           tsDcToVmFolder tsCrToHost tsCrToRp tsRpToRp tsRpToVm].freeze
          def select_set
            [
              traversal_spec('tsFolder',            'Folder',          'childEntity',     ALL_FOLDERS),
              traversal_spec('tsDcToDsFolder',      'Datacenter',      'datastoreFolder', 'tsFolder'),
              traversal_spec('tsDcToHostFolder',    'Datacenter',      'hostFolder',      'tsFolder'),
              traversal_spec('tsDcToNetworkFolder', 'Datacenter',      'networkFolder',   'tsFolder'),
              traversal_spec('tsDcToVmFolder',      'Datacenter',      'vmFolder',        'tsFolder'),
              traversal_spec('tsCrToHost',          'ComputeResource', 'host'),
              traversal_spec('tsCrToRp',            'ComputeResource', 'resourcePool',    'tsRpToRp'),
              traversal_spec('tsRpToRp',            'ResourcePool',    'resourcePool',    'tsRpToRp'),
              traversal_spec('tsRpToVm',            'ResourcePool',    'vm'),
            ]
          end

          def selection_spec(names)
            (names.kind_of?(String) ? [names] : names).collect { |name| RbVmomi::VIM.SelectionSpec(:name => name) } if names
          end

          def traversal_spec(name, type, path, selectSet = nil)
            RbVmomi::VIM.TraversalSpec(:name => name, :type => type, :path => path, :selectSet => selection_spec(selectSet))
          end
        end
      end
    end
  end
end
