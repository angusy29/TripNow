# TripNow

Uses TFNSW Trip Planner API to find bus stops and train station platforms within some specified radius. 

Queries TFNSW endpoint /coord to obtain stops around some coordinate, and /departure_mon to obtain detailed attributes of a particular stop.
Searches made in the search bar use /stop_finder endpoint

## Features
* Drag user annotation
* Tweak search radius
* User location
* Centre in on user annotation
* Search for a place

The app presents data such as:
* Closest stops
* Name of each stop
* Suburb stop belongs in
* Distance to each stop
* Buses at a particular stop
* Planned departure time

And also real-time data:
* Bus estimated departure time
* Bus capacity

## Screenshots
<p align="center">
  <img src="Screenshots/radius.png" width="30%"/>
  <img src="Screenshots/pullup.png" width="30%"/>
  <img src="Screenshots/open.png" width="30%"/>
  <img src="Screenshots/stop.png" width="30%"/>
</p>

## Libraries
Pulley for iOS 10 Maps style pull up modal.

EHHorizontalSelectionView for horizontal list of buses at a stop.

## Supported devices
Only tested on iOS 11

## Known bugs to fix
* Find stops, which returns a positive number of stops, and then if we try to find stops where there are no stops existing this will cause an index out of range error in DrawerContentViewController

## To do
[x] Search a region

[x] Long press to set position of user's search coordinate

[ ] Find out a sequence of transport to take to get to a specified searched region

[ ] Fix StopInfoViewController to update waiting time
