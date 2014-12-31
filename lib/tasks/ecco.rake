# encoding: UTF-8
##########################################################################
# Copyright 2011 Applied Research in Patacriticism and the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################
require 'csv'


namespace :ecco do
   desc "Generate page-level RDF (params: src_dir=/path/to/page/csv/files file=page/results/file)"
   task :generate_page_rdf => :environment do
      src_dir = ENV['src_dir']
      src_file = ENV['file']
      raise "Source directory is required!" if src_file.nil?
      raise "File is required!" if src_file.nil?

      # make sure out directory exists
      if File.directory?("#{RDF_PATH}/arc_rdf_ECCO_Pages/") == false
         system("mkdir #{RDF_PATH}/arc_rdf_ECCO_Pages/")
      end

      # parse the CSV file that maps work_id to URI
      work_info = {}
      CSV.foreach( "#{src_dir}/work_uri.csv", { :headers => true, :col_sep => "\t"}) do |row|
         work_info[row[0]] = { :uri=>row[1].strip }
      end

      # Run through the CSV file with page file data and generate RDF for each
      CSV.foreach( "#{src_dir}/#{src_file}", { :headers => true, :col_sep => "\t"}) do |row|
         # pull the text file path for this result and parse it out
         # into useful bits; work_id, page file and page number
         txt_path = row[3]
         bits = txt_path.split('/')
         work_id = bits[bits.length-3]
         txt_file = bits[bits.length-1]
         page_num = txt_file.split('.')[0]
         work = work_info[work_id]
         if work.nil?
            puts "ERROR: unexpected work ID #{work_id} found in input file!"
            next
         end

         # find the master RDF file that contains this edition
         if work[:template].nil?
            cmd = "grep #{work[:uri]} #{RDF_PATH}/arc_rdf_ECCO/*.rdf"
            result = `#{cmd}`
            if !result.empty?
               rdf = result.split(":")[0]
               puts "Work #{work_id} found in #{rdf}; generating RDF template"

               # Extract template for pages from original RDF file
               marker = "<recreate:collections rdf:about=\"#{work[:uri]}\">"
               end_mark = "</recreate:collections>"
               rdf_file = File.open(rdf, "r")
               data = rdf_file.read
               idx = data.index(marker)
               data = data[idx..data.length]
               idx = data.index(end_mark)
               data = data[0..(idx+end_mark.length)]
               data.gsub!(/<(collex:text).*(<\/collex:text>)/,"<collex:text>#TXT#</collex:text>")
               data.gsub!(/<\/dc:title>/,"</dc:title>\n\t<collex:page>#PAGE#</collex:page>")
               data.gsub!(/<collex:archive>ECCO/,"<collex:archive>ECCO_Pages")
               work[:template] = data
            else
               puts "ERROR: unable to find RDF for work #{work_id}"
               next
            end
         end

         # at this point, we have a valid template and path to page text. Generate RDF
         page_file = File.open(txt_path, "r")
         page = page_file.read
         out = work[:template].gsub(/#TXT#/,page.gsub(/\n/, " "))
         out.gsub!(/#PAGE#/,page_num)
         tgt_uri = work[:uri].split("/").last
         page_uri = "#{tgt_uri}_#{page_num.rjust(4,"0")}"
         out.gsub!(/#{tgt_uri}/,page_uri)

         out_file = "#{RDF_PATH}/arc_rdf_ECCO_Pages/#{page_uri}.rdf"
         File.open(out_file, "wb") { |f| f.write(out) }
      end
   end

   desc "Mark archive_ECCO texts for typewright (param: file=/text/file/path/one/item/per/line)"
   task :typewright_enable => :environment do

      file = ENV['file']
      if file == nil
         puts "Usage: call with file=/text/file\nThe text file should have a list of 10-digit numbers, with one of them per line."
      else
         start_time = Time.now
         dst = Solr.new("archive_ECCO")
         has_dot = false
         num_added = 0
         num_missing = 0
         count = 0
         File.open(file).each_line{ |text|
            uri = "lib://ECCO/#{text.strip()}"
            begin
               print "\n#{count}" if count % 1000 == 0
               print '.' if count % 50 == 0
               count += 1

               # TODO-PER: Couldn't get the modify to work
               #dst.modify_object(uri, 'typewright', true)
               obj = dst.full_object(uri)
               obj['typewright'] = true
               dst.add_object(obj, false, false)
               has_dot = true
               num_added += 1
            rescue SolrException => e
               puts "" if has_dot
               has_dot = false
               puts e.to_s
            num_missing += 1
            end
         }

         dst.commit()
         puts "\nNumber of documents added to typewright: #{num_added}"
         puts "Number of documents not found: #{num_missing}"
         puts "All items processed into the test index. If the test index looks correct, then merge it into the live index with:"
         puts "rake solr_index:merge_archive archive=ECCO"
         finish_line(start_time)
      end
   end

   desc "Unmark texts for typewright (param: [0000000000-0000000001-0000000002])"
   task :typewright_disable, [:uris] => :environment  do |t, args|
      uris = args[:uris]
      if uris == nil
         puts "Usage: call with [0000000000-0000000001-0000000002]\nThe parameters are a list of 10-digit numbers, with dashes in between."
      else
         start_time = Time.now
         src = Solr.factory_create(:live)
         dst = Solr.new("archive_ECCO")
         has_dot = false
         num_added = 0
         num_missing = 0
         uris = uris.split('-')
         uris.each{ |text|
            uri = "lib\\://ECCO/#{text.strip()}"
            begin
               obj = src.full_object(uri)
               obj['typewright'] = false
               dst.add_object(obj, false, false)
               print '.'
               has_dot = true
               num_added += 1
            rescue SolrException => e
               puts "" if has_dot
               has_dot = false
               puts e.to_s
            num_missing += 1
            end
         }

         dst.commit()
         puts "\nNumber of documents removed from typewright: #{num_added}"
         puts "Number of documents not found: #{num_missing}"
         puts "All items processed into the test index. If the test index looks correct, then merge it into the live index with:"
         puts "rake solr_index:merge_archive archive=ECCO"
         finish_line(start_time)
      end
   end

   desc "Create all the RDF files for ECCO documents, using estc records and the spreadsheets and texts."
   task :create_rdf => :environment do
      start_time = Time.now
      TaskReporter.set_report_file("#{Rails.root}/log/ecco_error.log")
      puts("Processing spreadsheets...")
      hits = []
      process_ecco_spreadsheets(hits)
      puts("Sorting...")
      hits.sort! { |a,b| a['uri'] <=> b['uri'] }# sort here so we can determine
      # duplicates quickly
      puts("Processing fulltext...")
      process_ecco_fulltext(hits)
      puts("Marking for typewright...")
      mark_for_typewright( hits )

      puts("Sorting...")
      hits.sort! { |a,b| a['uri'] <=> b['uri'] }# sort here so out output is in
      # uri order

      # use an ECCO prefix, max size 500K, start at # 1000 and dont partition
      # into subdirs
      RegenerateRdf.regenerate_all(hits, "#{RDF_PATH}/arc_rdf_ECCO", "ECCO", 500000, 1000, false )
      finish_line(start_time)
   end

   def process_ecco_spreadsheets(hits, max_recs = 9999999)
      src = Solr.new("archive_estc")
      total_recs = 0
      total_added = 0
      total_already_found = 0
      total_cant_find = 0
      Dir["#{MARC_PATH}/ecco/*.csv"].each {|f|
         File.open(f, 'r') { |f2|
            text = f2.read
            lines = text.split("\n")
            lines.each {|line|
               total_recs += 1
               line = line.gsub('"', '')
               rec = line.split(',', 2)
               # remove zeroes from between the letter and the non-zero part of
               # the number
               reg_ex = /(.)0*(.+)/.match(rec[0])
               estc_id = reg_ex[1] + reg_ex[2]
               estc_uri = "lib://estc/#{estc_id}"
               begin
                  obj = src.full_object(estc_uri)
               rescue
                  TaskReporter.report_line("Can't find object: #{estc_uri}")
                  total_cant_find += 1
                  obj = nil
               end
               if obj.present?
                  arr = rec[1].split('bookId=')
                  if arr.length == 1
                     TaskReporter.report_line("Unusual URL encountered: #{rec[1]}")
                  else
                     arr2 = arr[1].split('&')
                     obj['archive'] = "ECCO"
                     obj['url'] = [ rec[1] ]
                     ecco_id = "lib://ECCO/#{arr2[0]}"
                     obj['uri'] = ecco_id
                     TaskReporter.report_line("No year_sort: #{estc_uri} #{obj['uri']}") if obj['year_sort'] == nil
                     TaskReporter.report_line("No title_sort: #{estc_uri} #{obj['uri']}") if obj['title_sort'] == nil
                  hits.push(obj)
                  total_added += 1
                  #puts "estc: #{estc_id} ecco: #{ecco_id}"
                  end
               end
               puts("Total: #{total_recs} Added: #{total_added} Found: #{total_already_found} Can't find: #{total_cant_find}") if total_recs % 500 == 0
               return if total_recs >= max_recs
            }
         }
      }
      TaskReporter.report_line("Finished: Total: #{total_recs} Added: #{total_added} Found: #{total_already_found} Can't find: #{total_cant_find}")
   end

   def process_ecco_fulltext(hits)
      require "#{Rails.root}/lib/tasks/indexing/marc/lib/process_gale_objects.rb"
      include ProcessGaleObjects
      src = Solr.new(["archive_estc"])
      count = 0
      GALE_OBJECTS.each {|arr|
         filename = arr[0]
         estc_uri = arr[1]
         url = arr[3]
         text = ''
         File.open("#{ECCO_PATH}/#{filename}.txt", "r") { |f|
            text = f.read
         }
         begin
            obj = src.full_object(estc_uri)
         rescue
            TaskReporter.report_line("Can't find object: #{estc_uri}")
         end
         if obj.present?
            obj['text'] = text
            obj['has_full_text'] = true
            obj['freeculture'] = false
            obj['source'] = "Full text provided by the Text Creation Partnership."
            obj['archive'] = "ECCO"
            obj['url'] = [ url ]
            arr = url.split('bookId=')
            if arr.length == 1
               TaskReporter.report_line("Unusual URL encountered: #{url}")
            else
               arr2 = arr[1].split('&')
               obj['uri'] = "lib://ECCO/#{arr2[0]}"
               TaskReporter.report_line("No year_sort: #{estc_uri} #{obj['uri']}") if obj['year_sort'] == nil
               TaskReporter.report_line("No title_sort: #{estc_uri} #{obj['uri']}") if obj['title_sort'] == nil
               index = find_hit(hits, obj)
               if index == -1
               hits.push(obj)
               else
               hits[index] = obj
               end
            end
         end
         count += 1
         TaskReporter.report_line("Processed: #{count}") if count % 500 == 0
      }
   end

   def find_hit(hits, target)
      hits.each_with_index { |hit, i|
         return i if hit['uri'] == target['uri']
         return -1 if hit['uri'] > target['uri']
      }
      return -1
   end

   def mark_for_typewright( hits )

      typewright_list = load_typewright_list( )
      hits.each_with_index{ |hit, i|
         if typewright_list.include? hit['uri'].strip
            hits[ i ]['typewright'] = true
         else
            hits[ i ]['typewright'] = false
         end
      }
   end

   def load_typewright_list( )

      typewright_list = []
      filename = "ecco_tw_enabled.txt"
      File.foreach(filename) { |line|
         line.strip!
         #puts "Adding lib://ECCO/#{line}"
         typewright_list.push( "lib://ECCO/#{line}" )
      }
      return( typewright_list )
   end

end
