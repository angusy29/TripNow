# TripNow

Uses TFNSW Trip Planner API to find bus stops and train station platforms within some specified radius. 

Queries TFNSW endpoint /coord to obtain stops around some coordinate, and /departure_mon to obtain detailed attributes of a particular stop.

## Features
* Drag user annotation
* Tweak search radius
* User location
* Centre in on user annotation

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
  <img src="Screenshots/radius.png" width="50%"/>
  <img src="Screenshots/pullup.png" width="50%"/>
  <img src="Screenshots/open.png" width="50%"/>
  <img src="Screenshots/stop.png" width="50%"/>
</p>

## Libraries
Pulley for iOS 10 Maps style pull up modal.

EHHorizontalSelectionView for horizontal list of buses at a stop.

## Supported devices
Currently only supports iOS 11 due to the use of MKMarkerAnnotationView

## To do
* Search a region
* Fix StopInfoViewController to update waiting time
