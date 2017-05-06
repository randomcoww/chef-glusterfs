class ChefGlusterfs
  class Resource
    class PeerProbe < Chef::Resource
      resource_name :glusterfs_peer_probe

      default_action :send
      allowed_actions :send

      property :peer_host, String
      property :timeout, Integer, default: 120
    end
  end
end
