
Elo = require "./elo"
Match = require "./match"
User = require "./user"
Player = require "./player"
Status = require "./status"

module.exports =
class Ladder

	stats: new UserStats()

	@player_object: {
		rating: 1500
		wins: 0
		losses: 0
		matches: []
	}

	# A map of uids and Player objects.
	players: {}

	# An array containing the uids of every Player ordered by rank.
	player_rankings: []

	# A map of uids and Match objects.
	matches: {}

	# An array containing the uids of every Match
	# in the order they have taken place.
	match_order: []

	# Creates a Ladder object using the slug of the game and the Database object.
	# After the Ladder object is constructed, it will automatically
	# retrieve all the players from the database.
	constructor: (@slug, @database) ->

		@firebase = @database.firebase

		@retrievePlayers()

	# Gets a Player object given either a uid or User object.
	# If a player cannot be found, a temporary one will be created for
	#
	getPlayer: (user) ->

		if typeof user is 'string' # this is probably some user's name
			uid = user

		if typeof user is 'object' # this is (hopefully) a User object
			uid = user.uid

		if @players[uid]? then return @players[uid]

		console.log "[INFO] tried to find player with uid #{ uid } but it doesn't exist, creating a new one..."

		ref = @firebase.ref("ladders/#{ @slug }/users/#{ uid }")
		ref.once("value", (snapshot) ->
			if(!snapshot.exists())
				ref.set(Ladder.player_object).then(->
					console.log "Created Ranking Profile for UID: " + uid
				).catch((error) ->
					console.log "Failed trying to create Ranking Profile for UID: " + uid + ", " + error.message
				)
		)

	getPlayerByRank: (rank) -> @getPlayer(@player_rankings[rank])

	insertMatch: (set, players, games) =>
		now = Date.now()
		match = {
			time: now
			set: set
			players: players
			games: []
		}

		for game in games
			match.games.push {
				reports: [
					game, game
				]
			}

		@firebase.ref("ladders/#{ @slug }/matches").push(match)

	retrievePlayers: (callback) =>

		@players = {}
		@player_rankings = []

		query = @firebase.ref("ladders/smash-4/users").orderByChild("rating")
		time = Date.now()

		console.log "[INFO] retrieving players in #{ @slug }..."
		query.once "value", (ss) =>

			ss.forEach (child) =>

				uid = child.key
				player_object = child.val()

				if @database.userExists uid # use their user object
					user = @database.getUser uid
				else
					console.log "user not found for player uid #{ child.key }"
					user = new User(uid)

				@players[uid] = new Player(user, player_object)
				@player_rankings.push uid

				false

			console.log "[INFO] retrieval finished. #{ @player_rankings.length } players found in #{ (Date.now() - time) / 1000 }s."
			@player_rankings.reverse()
			if callback? then callback(@players)

	retrieveMatches: (callback) =>

		@matches = {}
		@match_order = []

		query = @firebase.ref("ladders/smash-4/matches").orderByChild("time")
		time = Date.now()

		console.log "[INFO] retrieving matches..."
		query.once "value", (ss) =>

			ss.forEach (child) =>

				match_object = child.val()
				uid = child.key

				@matches[uid] = new Match(match_object, this)
				@match_order.push(match_object)

				false

			console.log "[INFO] retrieval finished. #{ @match_order.length } matches found in #{ (Date.now() - time) / 1000 }s."
			if callback? then callback(@matches)

	updateStats: =>

		console.log "[INFO] clearing all player statistics..."

		for uid, player of @players
			player.reset_stats()

		console.log "[INFO] calculating player statistics..."

		for uid, match of @matches

			if match.status is Status.VALID

				match.player(0).apply_match(match)
				match.player(1).apply_match(match)

			@firebase.ref("ladders/smash-4/matches/#{ uid }/status").set(match.status)

		console.log "[INFO] calculations finished."

		@savePlayers()

	savePlayers: =>

		console.log "[INFO] saving current players to database..."
		for uid, player of @players
			@firebase.ref("ladders/smash-4/users/#{ uid }").set(player.db_object())

# class Rankings
#
# 	constructor: ->
#
# 	@createProfile: (uid) ->
# 		ref = db.ref("ladders/smash-4/users/#{uid}")
# 		ref.once("value", (snapshot) ->
# 			if(!snapshot.val())
# 				ref.set({
# 					elo: 1500
# 					wins: 0
# 					losses: 0
# 					matches: []
# 				}).then(->
# 					console.log "Created Ranking Profile for UID: " + uid
# 				).catch((error) ->
# 					console.log "Failed trying to create Ranking Profile for UID: " + uid + ", " + error.message
# 				)
# 		)
