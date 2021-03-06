module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
	# Split out format if page_name includes ' using '
    # Example: When I go to the accounts page using json
    page_name, format = page_name.split(' using ')
	case page_name

	when /the home\s?page/
	  '/'

	when /the login page/
	  new_user_session_path

	when /the sign out link/
	  destroy_user_session_path

	when /the search page/
	   "/search"

	when /the show ([^\s]+) ([^\s]+) page/
		"/#{$1}/#{$2}"

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym, :format => format)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
