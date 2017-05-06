class ChefGlusterfs
  class Provider
    class Peer < Chef::Provider
      include Chef::Mixin::Which
      include Chef::Mixin::ShellOut

      provides :glusterfs_peer, os: "linux"

      def load_current_resource
        @current_resource = ChefGlusterfs::Resource::Peer.new(new_resource.name)

        set_current_glusterd_info
        current_resource
      end

      def action_create
        converge_by("Create glusterfs peer: #{new_resource}") do
          recover_glusterd_info

          ## service needs to be up for this
          glusterfs_service.run_action(:start)

          peer_hosts = new_resource.peer_hosts

          host = peer_hosts.pop
          while !try_peer_probe(host)
            host = peer_hosts.pop

            if host.nil?
              Chef::Log.error("Probe failed for all peers")
              break
            end
          end

        end if current_resource.content.emtpy?

        ## this should get written after initial peer probe if not already there
        set_current_glusterd_info
        ## save content to data bag for node recovery
        save_current_glusterd_info
      end


      private

      def try_peer_probe(host)
        Timeout::timeout(new_resource.timeout) {
          while peer_probe(host).error?
            Chef::Log.info("Waiting #{new_resource.timeout} seconds for #{host} to come up...")
            sleep 1
          end
        }
        return true

      rescue => e
        Chef::Log.warn("Peer probe timed out for #{host}")
        return false
      end

      ## if glusterd info is empty and a previously saved entry exists, write it
      ## should allow peer probing for recovery
      def recover_glusterd_info
        if current_resource.content.empty? &&
          !new_resource.content.nil?

          glusterfs_service.run_action(:stop)

          Chef::Resource::File.new(new_resource.glusterd_info_path, run_context).tap do |r|
            r.content new_resource.content
          end.run_action(:create)
        end
      end

      ## check this at beginning for servers that are already bootstrapped
      ## if it exists, the peers should already be setup
      def set_current_glusterd_info
        if ::File.exist?(new_resource.path)
          current_resource.content(::File.read(new_resource.path))
        else
          current_resource.content('')
        end
      end

      ## save the generated glusterd info to data bag if
      ## databag entry doesn't already exist
      ## this is needed for node recovery
      def save_current_glusterd_info
        if new_resource.content.nil? &&
          !current_resource.content.empty?

          Dbag::Keystore.new(
            new_resource.data_bag,
            new_resource.data_bag_item
          ).put(new_resource.key, current_resource.content)
        end
      end


      def glusterfs_service
        @glusterfs_service ||= Chef::Resource::Service.new('glusterfs-server', run_context).tap do |r|
        end
      end

      def peer_probe(host)
        shell_out("#{gluster_command} peer probe #{host}")
      end

      def gluster_command
        @gluster_command ||= which('gluster')
      end
    end
  end
end
