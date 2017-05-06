class ChefGlusterfs
  class Resource
    class GlusterdInfo < Chef::Resource
      resource_name :glusterfs_glusterd_info

      default_action :create
      allowed_actions :create, :save, :save_if_missing

      property :data_bag, String
      property :data_bag_item, String
      property :key, String

      property :content, String, default: lazy { get_content }
      property :path, String, default: lazy { Glusterfs::GLUSTERD_INFO_PATH }

      private

      def get_content
        Dbag::Keystore.new(
          data_bag, data_bag_item
        ).get(key)
      end
    end
  end
end
