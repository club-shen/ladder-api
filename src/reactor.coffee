
module.exports =
class Reactor

	class Event

		callbacks: []

		constructor: (@name) ->

	constructor: ->

	events: {}

	registerEvent: (eventName) -> @events[eventName] = new Event(eventName)

	eventExists: (eventName) -> @events[eventName]?

	dispatchEvent: (eventName, args) -> @events[eventName].callbacks.forEach (callback) ->

		callback(args)

	addEventListener: (eventName, callback) -> @events[eventName].callbacks.push(callback)
