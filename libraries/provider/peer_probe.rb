class ChefGlusterfs
  class Provider
    class PeerProbe < Chef::Provider
      include Chef::Mixin::Which
      include Chef::Mixin::ShellOut

      provides :glusterfs_peer_probe, os: "linux"

      def load_current_resource
        @current_resource = ChefGlusterfs::Resource::PeerProbe.new(new_resource.name)
        current_resource
      end

      def action_send
        Timeout::timeout(new_resource.timeout) {
          while peer_probe(new_resource.peer_host).error?
            Chef::Log.info("Waiting #{new_resource.timeout} seconds for #{new_resource.peer_host} to come up...")
            sleep 1
          end
        }
      end


      private

      def peer_probe(host)
        shell_out("#{gluster_command} peer probe #{host}")
      end

      def gluster_command
        @gluster_command ||= which('gluster')
      end
    end
  end
end
