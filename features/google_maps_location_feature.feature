@javascript
Feature: populate the event panel with event details
  As a user and admin
  to clearly convey and understand the location of an event
  I want to use google maps to find and show the location detail

Background: events have already been added to the database
  Given the following events exist:
    | name             | organization       | description                               | venue_name                 | st_number | st_name    | city     | zip   | start                | end                  | how_to_find_us     |
    | Nature Walk      | Nature in the City | A walk through the city                   | The Old Town Hall          | 145       | Jackson st | Glendale | 90210 | March 19 2015, 16:30 | March 19 2015, 20:30 | First door on left |
    | Green Bean Mixer | Green Carrots      | If you like beans you'll like this event! | San Francisco City Library | 45        | Seneca st  | Phoenix  | 91210 | April 20 2015, 8:30  | April 21 2015, 8:30  | Second door on left|

  And I am on the calendar page

Scenario: see the google maps location in the event details show panel
  Given the month is April 2015
  When I click on "Green Bean Mixer" in the calendar
  Then the panel should display a google map in its location field

Scenario: use google maps to add location to event edit panel
  Given I am logged in as the admin
  And the month is March 2015
  When I click on "Nature Walk" in the calendar
  And I click on the edit event button
  Then I should be able to specify the location through google maps
