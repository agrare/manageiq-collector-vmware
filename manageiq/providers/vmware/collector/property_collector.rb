module ManageIQ
  module Providers
    module Vmware
      class Collector
        module PropertyCollector
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
            [
              RbVmomi::VIM.PropertySpec(
                :type    => 'ManagedEntity',
                :pathSet => ['name', 'parent']
              )
            ]
          end

          def select_set
            [
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsFolder', :type => 'Folder', :path => 'childEntity',
                :selectSet => [
                  RbVmomi::VIM.SelectionSpec(:name => 'tsFolder'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsDcToDsFolder'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsDcToHostFolder'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsDcToNetworkFolder'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsDcToVmFolder'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsCrToHost'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsCrToRp'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsRpToRp'),
                  RbVmomi::VIM.SelectionSpec(:name => 'tsRpToVm')
                ]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsDcToDsFolder', :type => 'Datacenter', :path => 'datastoreFolder',
                :selectSet => [RbVmomi::VIM.SelectionSpec(:name => 'tsFolder')]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsDcToHostFolder', :type => 'Datacenter', :path => 'hostFolder',
                :selectSet => [RbVmomi::VIM.SelectionSpec(:name => 'tsFolder')]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsDcToNetworkFolder', :type => 'Datacenter', :path => 'networkFolder',
                :selectSet => [RbVmomi::VIM.SelectionSpec(:name => 'tsFolder')]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsDcToVmFolder', :type => 'Datacenter', :path => 'vmFolder',
                :selectSet => [RbVmomi::VIM.SelectionSpec(:name => 'tsFolder')]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsCrToHost', :type => 'ComputeResource', :path => 'host',
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsCrToRp', :type => 'ComputeResource', :path => 'resourcePool',
                :selectSet => [RbVmomi::VIM.SelectionSpec(:name => 'tsRpToRp')]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsRpToRp', :type => 'ResourcePool', :path => 'resourcePool',
                :selectSet => [RbVmomi::VIM.SelectionSpec(:name => 'tsRpToRp')]
              ),
              RbVmomi::VIM.TraversalSpec(
                :name => 'tsRpToVm', :type => 'ResourcePool', :path => 'vm',
              ),
            ]
          end
        end
      end
    end
  end
end
