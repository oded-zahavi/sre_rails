class GemfileDataController < ApplicationController

	require 'pry'
	require 'mongoid'
	require './lib/gemfile_parser_entry'

	before_filter :init

	def init
		Mongoid.load!("config/mongoid.yml", Rails.env)
	end

	def index
		@data = GemfileParserEntry.all.to_json.html_safe
	end
end
