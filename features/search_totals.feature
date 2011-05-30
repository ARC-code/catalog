Feature: Search totals

	So that a web site can show how many objects are in the index for searching
	As a federated web site or an anonymous visitor
	I want to get the total number of objects and the total number of archives in the index.

	Scenario: Get solr resources totals
		Given I am not authenticated
		When I go to the totals search index page using xml
		Then the response status should be "200"
		And the xml has the structure "xsd/totals.xsd"
		And the xml "name" element array is "18thConnect,NINES"
		And the xml "total" element array is "673462,963720"
		And the xml "sites" element array is "15,105"

	Scenario: Browse to the solr resources totals
		Given I am not authenticated
		When I go to the totals search index page
		Then the response status should be "200"
		And I should see in this order "18thConnect, 673,462, 15, NINES, 963,720, 105"

