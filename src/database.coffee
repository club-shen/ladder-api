
User = require "./user"
Ladder = require "./ladder"
Reactor = require "./reactor"

# A wrapper class for the firebase database object.
#
module.exports =
class Database

	users: {}

	ladders: {}

	avaliable_ladders: {}

	reactor: new Reactor() # event system

	constructor: (@firebaseDB) ->

		@reactor.registerEvent "ready"

		@readUsers => @readLadders => @reactor.dispatchEvent "ready"

	@log = (message) -> console.log "shn-l | #{ message }"

	getLadder: (ladderSlug, seasonSlug) -> @ladders[ladderSlug] ? @ladders[ladderSlug] = new Ladder(ladderSlug, seasonSlug, this)

	userExists: (uid) -> @users[uid]?

	getUser: (uid) -> @users[uid]

	# Retrieves all Users from the database.
	#
	# @param {Function} callback the function to call after the operation
	#
	readUsers: (callback) ->

		Database.log "reading users from database..."

		@users = {}

		success = (ss) =>

			ss.forEach (child) =>

				@users[child.key] = new User(child.key, child.val())

				false

			Database.log "done. #{ Object.keys(@users).length } users found."

			callback()

		error = (err) ->

			Database.log err

		@firebaseDB.ref("users").once("value", success, error).catch(error)

	readLadders: (callback) ->

		Database.log "reading users from database..."

		@avaliable_ladders = {}

		@firebaseDB.ref("ladders").once "value", (ss) =>

			ss.forEach (ladderSnapshot) =>

				ladderSlug = ladderSnapshot.key

				@avaliable_ladders[ladderSlug] = {}

				if ladderSnapshot.hasChild "title"
					@avaliable_ladders[ladderSlug].title = ladderSnapshot.child("title").val()
				else
					@avaliable_ladders[ladderSlug].title = ladderSlug

				if ladderSnapshot.hasChild "seasons"
					@avaliable_ladders[ladderSlug].seasons = Object.keys ladderSnapshot.child("seasons").val()
				else
					@avaliable_ladders[ladderSlug].seasons = []

				false

			Database.log "done. #{ Object.keys(@avaliable_ladders).length } ladders found."

			for ladderSlug, obj of @avaliable_ladders
				Database.log "    - #{ obj.title } (#{ ladderSlug })"
				for seasonSlug in obj.seasons
					Database.log "        - #{ seasonSlug }"

			callback()

	createLadder: (ladderSlug, title) =>

		@firebaseDB.ref("ladders")

	on: (event, callback) ->

		if @reactor.eventExists event then @reactor.addEventListener event, callback
