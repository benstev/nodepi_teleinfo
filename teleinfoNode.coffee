  
teleinfo = require 'teleinfo'
util = require 'util'
config = require './config'

log4js = require 'log4js'
log = log4js.getLogger()
log.setLevel config.logging_level
log.info util.format('logging level [%s]', config.logging_level)

sending = true
intRes = {}
sampleCnt = 0
trameEvents = teleinfo config.serial_port


recordSample = (data) ->
	for field, f of config.teleinfo.summary_fields
		if f.func == 'avg'
			intRes[field] = intRes[field] + data[field]
		else if f.func == 'max'
			intRes[field] = Math.max intRes[field], data[field]
	sampleCnt += 1
 
 
trameEvents.on 'tramedecodee', (data) ->
	if sending
		msg = {}
		msg[field] = data[field] for field in config.teleinfo.fields
		mstr = JSON.stringify(msg)
		log.debug util.format('publish message <%s> to topic <%s>', mstr, config.teleinfo.topic)
		mqtt.publish config.teleinfo.topic, mstr
		recordSample data
		
trameEvents.on 'error', (err) ->
	log.warn util.inspect(err)


log.info util.format('Connecting to mqtt <%s:%s>', config.mqtt.host, config.mqtt.port)
mqtt = require('mqtt').createClient(config.mqtt.port, config.mqtt.host);

mqtt.on 'connect', ->
	log.info 'mqtt connected!'
	connected = true

returnStatusCode = () ->
	if sending
		mqtt.publish config.teleinfo.status_topic, 'I'
		log.debug util.format('publish message <I> to topic <%s>', config.teleinfo.status_topic)
	else 
		mqtt.publish config.teleinfo.status_topic, 'O'
		log.debug util.format('publish message <O> to topic <%s>', config.teleinfo.status_topic)

setStatus = (status) -> 
	sending = status
	returnStatusCode()


mqtt.on 'message', (topic, message) ->
	log.debug util.format('Mqtt message <%s> received from topic <%s>', message, topic)
	cc = message.toUpperCase()
	switch cc[0]
		when "S" then returnStatusCode()
		when "I" then setStatus true
		when "O" then setStatus false
		else go log.warn 'Unknown command code received!'

delay = (time, fn) ->
	setInterval fn, time

resetIntegral= () ->
	intRes[field] = 0 for field, f of config.teleinfo.summary_fields
	sampleCnt = 0

sendIntegral = () ->
	if sending and sampleCnt > 0
		for field, f of config.teleinfo.summary_fields
			if f.func == 'avg'
				v = intRes[field] / sampleCnt
			else
				v = intRes[field]
			astr = JSON.stringify(v)
			log.debug util.format('SEND INTEGRAL <%s> to topic <%s>', astr, f.topic)
			mqtt.publish f.topic, astr
	resetIntegral()
	
resetIntegral()
delay config.teleinfo.integration_seconds * 1000, sendIntegral	
mqtt.subscribe config.teleinfo.command_topic
