class GemfileParserEntry

  include Mongoid::Document
  include Mongoid::Timestamps

  store_in client:     'cluster1'
  store_in collection: 'gemfile_data'

  field :gem_name,    type: String
  field :gem_version, type: String
  field :repo_name,   type: String

  def self.add(gem_name, gem_version, repo_name)
    new_record = GemfileParserEntry.new(gem_name: gem_name, gem_version: gem_version, repo_name: repo_name)
    new_record.save()
  end
end
