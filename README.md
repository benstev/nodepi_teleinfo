# nodepi/teleinfoNode

nodepi is a set of node.js daemons running on a Raspberry Pi that will acquire various sensors from home automation
and publish them onto an MQTT broker

teleinfoNode acquires various parameters from the EDF electricity meter reading ("télé-information")

## Requirements

* [teleinfo](https://www.npmjs.org/package/teleinfo)
* [mqtt] (https://github.com/adamvr/MQTT.js/)
* log4js


## Configuration

Edit the config.js file.

### topics
2 topics need to be configured:
* "topic"
 
to collect the real-time readings (approx. 1 per second)
* "summary_topic" 

to collect the averaged readings on a slower (configurable) pace

### teleinfo fields 
* raw values
"fields" holds the list of considered fields from the teleinfo.
* averaged values
"summary_fields" holds the list of averaged fields and the aggregation function (currently "avg" or "max" onmy implemenented).

## Running it

Usually run with forever


