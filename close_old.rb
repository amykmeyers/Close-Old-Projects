
#This script takes a .csv output of Projects that need to be closed and closes them.
#Many thanks to Paul Jackson, Barry Mullan and Dave Thomas for their guidance and knowledge.
#It's elegant enough for a first ruby script... unsupported, Shannon Mason
require 'rubygems'
require 'rally_api'
require 'json'
require 'csv'
class CloseProjects
  def initialize
    headers = RallyAPI::CustomHttpHeader.new()
    headers.name = "Close Project Script"
    headers.vendor = "Rally Software, Unsupported"
    headers.version = "V. 1"


    config = {:base_url => "https://rally1.rallydev.com/slm"}
    config[:username] = "YourEmailAddress@company.com"
    config[:password] = "YourPassword"
    #config[:api_key] = "API KEY HERE"
    config[:workspace] = "Workspace Name"
    config[:project] = "Project Name"
    config[:headers] = headers

    @rally = RallyAPI::RallyRestJson.new(config)


  end

  def find_project(name)

    test_query = RallyAPI::RallyQuery.new()
    test_query.type = "project"
    test_query.fetch = "Name,ObjectID,CreationDate"
    test_query.page_size = 200       #optional - default is 200
    test_query.limit = 1000          #optional - default is 99999
    test_query.project_scope_up = false
    test_query.project_scope_down = true
    test_query.order = "Name Asc"
    test_query.query_string = "(Name = \"#{name}\")"

  end

  #unsure whether I would need to do this following:
  def parse_csv
    CSV.parse(File.read("DeleteMe.csv")) do |row|
      puts row.class
      #project = @rally.find(RallyAPI::RallyQuery.new({:type => :project, :query_string => "(Name = #{row["Name"]})"}))
      project = @rally.find(RallyAPI::RallyQuery.new({:type => :project, :query_string => "(Name = \"#{row.first}\")"}))
      puts project
      project = project.first
      fields = {}
      fields[:state] = 'Closed'
      fields[:notes] = close_reason(project)
      project.update(fields)
    end
    # File.open("DeleteMe.csv", "r") do |f|
    #   f.each_line do |line|
    #     puts line
    #   end
    #   end
  end
end
def close_reason(project)
  return "Folder closed on #{Time.now.utc} due to no activity."
end

# File is closed automatically at end of blockend
#this will see the method and then run it
mason = CloseProjects.new
mason.find_project("Tower 2")
mason.parse_csv
