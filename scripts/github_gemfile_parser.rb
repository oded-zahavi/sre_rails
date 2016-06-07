
require 'rubygems'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'uri'
require 'base64'
require 'json'
require 'yaml'
require 'bundler'
require 'mongoid'
require 'ruby-progressbar'
Bundler.require

require '../lib/gemfile_parser_entry'

PER_PAGE = 50

GEMINABOX_SERVER = ""
GEMINABOX_USER   = ""
GEMINABOX_PASS   = ""

GIT_AUTH_TOKEN = '768b0f790b5478c6c91bd6ceaa1f091abe00d6e4'

$env                         = 'production'
$input                       = nil
$output                      = nil
$full                        = false

OptionParser.new do |opt|
  opt.on('--env    value') { |o| $env    = o }
  opt.on('--input  value') { |o| $input  = o }
  opt.on('--output value') { |o| $output = o }
  opt.on('--full   value') { |o| $full   = (o == 'true') }
end.parse!

def run!
	res = {}

	if $input.nil?
		uri = URI("https://api.github.com")
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		header = {'Content-type' => 'application/json', 'Authorization' => "token #{GIT_AUTH_TOKEN}"}
		page = 0
binding.pry
		begin			
			page = page + 1
			request = Net::HTTP::Get.new("/search/code?q=filename:gemfile.lock+user:fiverr&page=#{page}&per_page=#{PER_PAGE}", header)
			repos = http.request(request)
			repos = JSON.parse(repos.body) unless repos.nil? || repos.body.nil?
			progressbar = ProgressBar.create total: repos['total_count'].to_i, format: "%a %P% Processed: %c from %C" if progressbar.nil?
			repos['items'].each do |file|
			    request = Net::HTTP::Get.new(file['url'], header)
			    file_contenct = http.request(request)
			    file_contenct = JSON.parse(file_contenct.body) unless file_contenct.nil? || file_contenct.body.nil?
				progressbar.progress += 1
				lockfile = Bundler::LockfileParser.new(Base64.decode64(file_contenct['content']))
				gems_to_parse = $full ? lockfile.specs : lockfile.specs.select {|x| (lockfile.specs.map {|x| x.name} & lockfile.dependencies.map {|x| x.name}).include? x.name}
				gems_to_parse.each do |spec|
					res[spec.name] = {} if res[spec.name].nil?
					res[spec.name][spec.version.to_s] = [] if res[spec.name][spec.version.to_s].nil?
					res[spec.name][spec.version.to_s] << file['repository']['name']
				end
			end	
		end while page * PER_PAGE < repos['total_count'].to_i
	else
  		res = YAML::load_file($input)
	end
	
	if $output.nil?
		Mongoid.load!("../config/mongoid.yml", $env)
		GemfileParserEntry.delete_all
		res.each do |gem_name, versions|
			versions.each do |gem_version, repos|
				repos.each do |repo_name| 
					GemfileParserEntry.add(gem_name, gem_version, repo_name)
				end
			end
		end
	else
		File.open($output, "w") do |file|
		  file.write res.to_yaml
		end
	end
end

run! 