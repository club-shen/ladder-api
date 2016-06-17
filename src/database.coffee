
User = require "./user"
Ladder = require "./ladder"
Reactor = require "./reactor"

# A wrapper class for the firebase database object.
#
module.exports =
class Database

	users: {}

	ladders: {}

	reactor: new Reactor() # event system

	constructor: (@firebase) ->

		@reactor.registerEvent "ready"

		@retrieveUsers => @reactor.dispatchEvent "ready"

	getLadder: (slug) -> @ladders[slug] ? @ladders[slug] = new Ladder(slug, this)

	userExists: (uid) -> @users[uid]?

	getUser: (uid) -> @users[uid]

	retrieveUsers: (callback) ->

		console.log "[INFO] retrieving users from database..."

		@users = {}

		@firebase.ref("users").once "value", (ss) =>

			ss.forEach (child) =>

				@users[child.key] = new User(child.key, child.val())

				false

			console.log "[INFO] retrieval finished. #{ Object.keys(@users).length } users found."

			callback()

	on: (event, callback) ->

		if @reactor.eventExists event then @reactor.addEventListener event, callback
