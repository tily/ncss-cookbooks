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
  def upload(bucket_name)
    pwd = Dir.pwd
    unless File.exists?("#{pwd}/VERSION") || File.readble?("#{pwd}/VERSION")
      abort "Error: VERSION file does not exists."
    end
    version = File.read("#{pwd}/VERSION").chomp

    bucket = ncss.buckets[bucket_name]
    unless bucket.exists?
      abort "Error: Bucket #{bucket_name} does not exist."
    end
    object = bucket.objects["v#{version}/cookbooks.tgz"]

    Dir.mktmpdir('ncss-cookbooks') do |dir|
      FileUtils.mkdir_p("#{dir}/cookbooks/")
      FileUtils.cp_r(Dir["#{pwd}/*"], "#{dir}/cookbooks/")

      FileUtils.cd(dir)
      cookbooks_tgz = Zlib::GzipWriter.new(File.open("cookbooks.tgz", "wb"))
      Archive::Tar::Minitar.pack('cookbooks', cookbooks_tgz)

      object.write(:file => "cookbooks.tgz")
      object.acl = :public_read
    end

    puts object.url_for(:read).to_s.gsub(/\?(.+)$/, '')
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
