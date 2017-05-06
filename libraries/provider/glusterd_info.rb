class ChefGlusterfs
  class Provider
    class GlusterdInfo < Chef::Provider

      provides :glusterfs_glusterd_info, os: "linux"

      def load_current_resource
        @current_resource = ChefGlusterfs::Resource::GlusterdInfo.new(new_resource.name)

        if ::File.exist?(new_resource.path)
          current_resource.content(::File.read(new_resource.path))
        else
          current_resource.content('')
        end

        current_resource
      end

      def action_create
        if !new_resource.content.nil? &&
          new_resource.content != current_resource.content

          converge_by("Create glusterfs peer: #{new_resource}") do
            glusterd_info_file.run_action(:create)
          end
        end
      end

      def action_save
        if !current_resource.content == '' &&
          new_resource.content != current_resource.content

          converge_by("Create glusterfs peer: #{new_resource}") do
            glusterd_info_keystore.put(current_resource.content)
          end
        end
      end

      def action_save_if_missing
        if new_resource.content.nil?
          action_save
        end
      end


      private

      def glusterd_info_file
        @glusterd_info_file ||= Chef::Resource::File.new(new_resource.path, run_context).tap do |r|
          r.content new_resource.content
        end
      end

      def glusterd_info_keystore
        Dbag::Keystore.new(
          new_resource.data_bag,
          new_resource.data_bag_item
        )
      end
    end
  end
end
