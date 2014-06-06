require "action_view"

if defined?(AssetSync)
AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.fog_directory = ENV['FOG_DIRECTORY']
  config.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  config.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  config.always_upload = ['badge.1.1.js', 'badge.nobackbone.1.1.js', 'badge.1.2.js']
  time = 1 * 24 * 60 * 60
  config.custom_headers = {
    "badge.js" => {
      :cache_control => "public, max-age=#{time}",
      :expires => "",
    },
   "badge.1.1.js" => {
     :cache_control => "public, max-age=#{time}",
     :expires => "",
   },
   "badge.1.2.js" => {
     :cache_control => "public, max-age=#{time}",
     :expires => "",
   },
   "badge.nobackbone.1.1.js" => {
     :cache_control => "public, max-age=#{time}",
     :expires => "",
   }
    
  }
  config.gzip_compression = true
end
class Sprockets::Helpers::RailsHelper::AssetPaths
    def digest_for(logical_path, digest_assets = digest_assets)
      if digest_assets && asset_digests && (digest = asset_digests[logical_path])
        return digest
      end

      if compile_assets
        if digest_assets && asset = asset_environment[logical_path]
          return asset.digest_path
        end
        return logical_path
      else
        raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
      end
    end
    def rewrite_asset_path(source, dir, options = {})
      if source[0] == ?/
        source
      else
        source = digest_for(source, true) unless options[:digest] == false
        source = File.join(dir, source)
        source = "/#{source}" unless source =~ /^\//
        source
      end
    end
end
end