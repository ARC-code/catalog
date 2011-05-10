Feature: Search with bad parameters

	So that a visitor can learn the correct way to call the web service
	As an anonymous visitor
	I want to see a clear error message when I have an error in my search parameters

	Scenario: Call with an unrecognized parameter
		Given I am not authenticated
		When I search with "q=+tree&xyy=7"
		Then the response status should be "400"
		And I should see "xyy is not a recognized parameter"

	Scenario: Call with unparseable parameter
		Given I am not authenticated
		When I search with "q=tree"
		Then the response status should be "400"
		And I should see "syntax error in parameter q"
		And I should see "must begin with + or -"

	Scenario: Call with the same parameter twice
		Given I am not authenticated
		When I search with "q=+tree&q=-hog"
		Then the response status should be "400"
		And I should see "syntax error in parameter q"
		And I should see "The parameter q appears twice."