class ChefGlusterfs
  class Resource
    class Peer < Chef::Resource
      resource_name :glusterfs_peer

      default_action :create
      allowed_actions :create

      property :peer_hosts, Array
      property :data_bag, String
      property :data_bag_item, String
      property :key, String

      property :content, String, default: lazy { get_content }
      property :path, String, default: lazy { Glusterfs::GLUSTERD_INFO_PATH }

      property :timeout, Integer, default: 120

      private

      def get_content
        Dbag::Keystore.new(
          data_bag, data_bag_item
        ).get(key)
      end
    end
  end
end
