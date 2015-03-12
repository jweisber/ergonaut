# If using Amazon S3
# CarrierWave.configure do |config|
#   config.storage = :fog
#   config.fog_credentials = {
#     :provider               => 'AWS',                           # required
#     :aws_access_key_id      => ENV['AWS_ACCESS_KEY'],           # required
#     :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],    # required
#   }
#   config.fog_directory  = ENV['AWS_S3_BUCKET']                     # required
#   config.fog_public     = false                                    # optional, defaults to true
#   config.fog_authenticated_url_expiration = 3.hour                 # expire links after 3 hours
#   #config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
#   config.root = Rails.root                                         # keep files outside /public
# end

CarrierWave.configure do |config|
  config.storage = :file  
  config.root = Rails.root
end

if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end
  
  # make sure our uploader is auto-loaded
  SubmissionUploader

  # use different dirs when testing
  CarrierWave::Uploader::Base.descendants.each do |klass|
    next if klass.anonymous?
    klass.class_eval do
      def cache_dir
        "#{Rails.root}/spec/support/uploads/tmp"
      end

      def store_dir
        "#{Rails.root}/spec/support/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
      end
    end
  end
end