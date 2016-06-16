
User = require "./user"
Ladder = require "./ladder"

# A wrapper class for the firebase database object.
#
module.exports =
class Database

	users: {}

	ladders: {}

	constructor: (@firebase) ->

		@retrieveUsers()

	getLadder: (slug) -> @ladders[slug] ? @ladders[slug] = new Ladder(slug, this)

	userExists: (uid) -> @users[uid]?

	getUser: (uid) -> @users[uid]

	retrieveUsers: ->

		console.log "[INFO] retrieving users from database..."

		@users = {}

		@firebase.ref("users").once "value", (ss) =>

			ss.forEach (child) =>

				@users[child.key] = new User(child.key, child.val())

				false

			console.log "[INFO] retrieval finished. #{ Object.keys(@users).length } users found."
