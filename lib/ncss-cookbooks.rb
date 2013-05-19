require 'zlib'
require 'fileutils'
require 'tmpdir'
require 'rubygems'
require 'thor'
require 'highline'
require 'aws-sdk'
require 'archive/tar/minitar'

class NcssCookbooks < Thor
  class_option :access_key_id, :alias => '-a'
  class_option :secret_access_key, :alias => '-s'

  desc 'create <bucket>', 'create ncss bucket'
  def create(bucket_name)
    ncss.buckets.create(bucket_name)
  end

  desc 'upload <bucket>', 'upload . to ncss bucket'
  option :verbose
  def upload(bucket_name)
    pwd = Dir.pwd
    unless File.exists?("#{pwd}/VERSION") || File.readble?("#{pwd}/VERSION")
      abort "Error: VERSION file does not exists."
    end
    version = File.read("#{pwd}/VERSION").chomp
    puts "Version is v#{version}"

    bucket = ncss.buckets[bucket_name]
    unless bucket.exists?
      abort "Error: Bucket #{bucket_name} does not exist."
    end
    object = bucket.objects["v#{version}/cookbooks.tgz"]

    Dir.mktmpdir('ncss-cookbooks-') do |dir|
      puts "Creating directory #{dir}/cookbooks/"
      FileUtils.mkdir_p("#{dir}/cookbooks/")

      puts "Copying files from #{@pwd} to #{dir}/cookbooks/"
      FileUtils.cp_r(pwd_files, "#{dir}/cookbooks/")

      puts "Archiving #{dir}/cookbooks/ to #{dir}/cookbooks.tgz"
      FileUtils.cd(dir)
      cookbooks_tgz = Zlib::GzipWriter.new(File.open("cookbooks.tgz", "wb"))
      Archive::Tar::Minitar.pack('cookbooks', cookbooks_tgz)

      if options[:verbose]
        puts "Archive includes:"
        system "tar tzvf cookbooks.tgz"
      end

      puts "Uploading #{dir}/cookbooks.tgz to bucket:#{bucket_name}, object:#{object.key}"
      object.write(:file => "cookbooks.tgz")
      object.acl = :public_read

      puts "Temporary directory #{dir} will be deleted automatically"
    end

    puts "Uploaded to " + object.url_for(:read).to_s.gsub(/\?(.+)$/, '')
  end

  private

  def ncss
    # TODO: option for west-1 endpoint
    @ncss ||= AWS::S3.new(
      :access_key_id => options[:access_key_id] || ENV['ACCESS_KEY_ID'] || HighLine.new.ask('Access Key Id: '),
      :secret_access_key => options[:secret_access_key] || ENV['SECRET_ACCESS_KEY'] || HighLine.new.ask('Secret Access Key: '),
      :s3_endpoint => 'ncss.nifty.com'
    )
  end
end
