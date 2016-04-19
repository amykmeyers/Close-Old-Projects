#This script was forked from Shannon Mason's original work. Thank you Shannon 
#A big thank you to Steve Rhoads for helping to make some changes
#This script takes a .csv output of Projects that need to be closed and closes them.
#It is unsupported.  Amy Meyers
require 'rubygems'
require 'rally_api'
require 'json'
require 'csv'
require 'logger'
require 'markaby'

class CloseProjects
  
  def initialize configFile
    headers = RallyAPI::CustomHttpHeader.new()
    headers.name = "Close Project Script"
    headers.vendor = "Rally Software, Unsupported"
    headers.version = "V. 1"


    config = {:base_url => "https://rally1.rallydev.com/slm"}
    #config[:username] = "YourEmailAddress@company.com"
    #config[:password] = "YourPassword"
    config[:api_key] = "API KEY HERE"
    config[:workspace] = "Workspace Name"
    #config[:project] = "Project Name"
    config[:headers] = headers

    file = File.read(configFile)
	config_hash = JSON.parse(file)

	#config[:username]   = config_hash["username"]
	#config[:password]   = config_hash["password"]
	config[:api_key]   = config_hash["api-key"] 
	config[:workspace] = config_hash["workspace"]
	#config[:project] = config_hash["project"] #we do not need project here we are going after all projects	
   puts "#{config[:api_key]}, #{config[:workspace]}"
   #puts "#{config[:username]}, #{config[:password]}, #{config[:workspace]}"
    @rally = RallyAPI::RallyRestJson.new(config)
    @csv_input_file 							= config_hash['csv-input-file']
  
    # Logger ------------------------------------------------------------
	@logger 				          	= Logger.new('./delete_inactive_projects.log')
	@logger.progname 						= "Delete Inactive Projects"
	@logger.level 		        	= Logger::DEBUG # UNKNOWN | FATAL | ERROR | WARN | INFO | DEBUG
    @logger.info "Starting Run"    
  end

  # def find_project(name)
  def find_project(objectid)

    test_query = RallyAPI::RallyQuery.new()
    test_query.type = "project"
    test_query.fetch = "Name,ObjectID,CreationDate"
    test_query.page_size = 200       #optional - default is 200
    test_query.limit = 1000          #optional - default is 99999
    test_query.project_scope_up = false
    test_query.project_scope_down = true
    test_query.order = "Name Asc"
    #Amy removed from original # test_query.query_string = "(Name = \"#{name}\")"
    test_query.query_string = "(ObjectID = \"#{objectid}\")"

    results = @rally.find(test_query)

    return results.first #must use the first syntax even though we are only querying for a single objectid 
  end

  #unsure whether I would need to do this following:
  def parse_csv
    #CSV.parse(File.read("DeleteMe.csv")) do |row|
    puts @csv_input_file
    CSV.foreach(@csv_input_file, headers:true) do |row|
      
      
     begin
      puts row.inspect
      puts "(ObjectID = \"#{row['ObjectID']}\")"
      #project = @rally.find(RallyAPI::RallyQuery.new({:type => :project, :query_string => "(Name = #{row["Name"]})"}))
      #project = @rally.find(RallyAPI::RallyQuery.new({:type => :project, :query_string => "(Name = \"#{row.first}\")"}))
      #project = @rally.find(RallyAPI::RallyQuery.new({:type => :project, :query_string => "(ObjectID = \"#{row['ObjectID']}\")"}))
      
      project = find_project(row['ObjectID'])
      puts "project we found #{project.Name}"
      #project = project.first
      fields = {}
      fields[:state] = 'Closed'
      fields[:notes] = close_reason(project)
      project.update(fields)
      
      rescue Exception => e
	    puts "Error closing project with ObjectID = \"#{row['ObjectID']}\"). Message: #{e.message}"
        @logger.debug "Error closing project with ObjectID = \"#{row['ObjectID']}\"). Message: #{e.message}"
        next
     end                    
      @logger.info "Project [#{project.Name}] closed on #{Time.now.utc} due to no activity."
      
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

mason = CloseProjects.new ARGV[0]
#mason.find_project("Tower 2")
mason.parse_csv