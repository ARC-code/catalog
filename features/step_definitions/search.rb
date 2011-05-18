require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(*selector_for(locator)) { yield } : yield
  end
end
World(WithinHelpers)

When /^I ([^\s]*) with <([^>]*)>$/ do |verb,obj|
	verb = "search/#{verb}" if verb != 'search'
	param = obj.gsub("+", "%2b").gsub(' ', '+').gsub('"', "%22")
	visit "/#{verb}?#{param}"
end

When /^I ([^\s]*) with <([^>]*)> using xml$/ do |verb,obj|
	verb = "search/#{verb}" if verb != 'search'
	param = obj.gsub("+", "%2b").gsub(' ', '+').gsub('"', "%22")
	visit "/#{verb}.xml?#{param}"
end


