require 'rest_client'

# This controller accepts POSTed document data that has been corrected by 
# TypeWright. Solr is updated with the new data, and the corrected text is
# written out to a separate directory so re-indexing will produce the 
# same results
#
class CorrectionsController < ApplicationController
  require 'uri'
  
  def create
    federation = Federation.find_by_name(params[:federation])
    ip = request.headers['REMOTE_ADDR']
    if federation && ip == federation.ip
      # corrected text is stored in a the 'correctedtext' directory that is a peer
      # to the main rdf directory
      out_path = RDF_PATH
      idx = out_path.rindex('/')
      out_path = "#{out_path[0...idx]}/correctedtext/#{params['archive']}"
      
      # Ensure that the out directory exists
      if !File.exist?(out_path)
        FileUtils.mkdir_p out_path  
      end
      
      # create a filename from the URI. URI format is like this:
      # lib://ECCO/1237801200
      # The ECCO part is already handled by the directory name above, so the
      # only unique bit needed is the number on the end
      doc_file_name = "#{File.basename( URI.parse(params['uri']).path)}.txt"
      File.open("#{out_path}/#{doc_file_name}", 'w') {|f| f.write(params['text']) }
      
      # Grab the corrected solr record from the POST params and convert it to JSO
      correction = []
      correction << params[:correction]
      doc_json = ActiveSupport::JSON.encode(correction)
      
      # Update SOLR by posing the json to the update url. Set the commit flag
      # so the changes autocommit.
      begin
        solr_url = "#{SOLR_URL}/update/json?commit=true"
        RestClient.post solr_url, doc_json, :content_type => "application/json"
        render :text => "OK", :status => :ok  
      rescue RestClient::Exception => rest_error
         puts rest_error.response
         render :text => rest_error.response, :status => rest_error.http_code
      rescue Exception => e
         puts rest_error.response
         render :text => e, :status => :internal_server_error
      end
      
    else
      render :text => "You do not have permission to do this.", :status => :unauthorized 
    end
  end
end
