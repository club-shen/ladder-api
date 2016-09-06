
Elo = require "./elo"
Match = require "./match"
User = require "./user"
Player = require "./player"
Status = require "./status"

module.exports =
class Ladder

	@player_object: {
		rating: 1500
		wins: 0
		losses: 0
		matches: []
	}

	@ref_title: (ladder_slug, season_slug) ->

		if season_slug?
			"ladders/#{ ladder_slug }/seasons/#{ season_slug }/title"
		else
			"ladders/#{ ladder_slug }/title"

	@ref_players: (ladder_slug, season_slug) ->
		"ladders/#{ ladder_slug }/seasons/#{ season_slug }/players"

	@ref_matches: (ladder_slug, season_slug) ->
		"ladders/#{ ladder_slug }/seasons/#{ season_slug }/matches"

	@ref_player: (ladder_slug, season_slug, player_uid) ->
		"ladders/#{ ladder_slug }/seasons/#{ season_slug }/players/#{ player_uid }"

	log: (message) -> console.log "shn-l #{ @ladder_slug }/#{ @season_slug } | #{ message }"

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
	constructor: (@ladder_slug, @season_slug, @database) ->

		@firebase = @database.firebaseDB

		@tag = "()"

		@retrievePlayers(=> @retrieveMatches(=> @updateStats()))

	# Gets a Player object given either a uid or User object.
	# If a player cannot be found, a temporary one will be created for
	#
	getPlayer: (user) ->

		if typeof user is 'string' # this is probably some user's name
			uid = user

		if typeof user is 'object' # this is (hopefully) a User object
			uid = user.uid

		if @players[uid]? then return @players[uid]

		throw new Error("Player with UID \"#{ uid }\" in #{ @tag } doesn't exist.")

	playerExists: (user) ->

		if typeof user is 'string' # this is probably some user's name
			uid = user

		if typeof user is 'object' # this is (hopefully) a User object
			uid = user.uid

		return @players[uid]?

	getPlayerByRank: (rank) -> @getPlayer(@player_rankings[rank])

	# Gets a Player object given the player's name.
	# This will return an *array* of Player objects, since it's possible
	# for multiple players to share the same name.
	getPlayersByName: (name) ->

		players = []

		for uid, player of @players
			if player.user.display_name.valueOf() is name
				players.push player

		return players

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

		@firebase.ref(Ladder.ref_matches(@ladder_slug, @season_slug)).push(match)

	retrievePlayers: (callback) =>

		@players = {}
		@player_rankings = []

		query = @firebase.ref(Ladder.ref_players(@ladder_slug, @season_slug)).orderByChild("rating")

		@log "retrieving players..."
		query.once "value", (ss) =>

			ss.forEach (child) =>

				uid = child.key
				player_object = child.val()

				if @database.userExists uid # use their user object
					user = @database.getUser uid
				else
					user = new User(uid)

				@players[uid] = new Player(user, player_object)
				@player_rankings.push uid

				false

			@log "retrieval finished. #{ @player_rankings.length } players found."
			@player_rankings.reverse()
			if callback? then callback(@players)

	retrieveMatches: (callback) =>

		@matches = {}
		@match_order = []

		query = @firebase.ref(Ladder.ref_matches(@ladder_slug, @season_slug)).orderByChild("time")

		@log "retrieving matches..."
		query.once "value", (ss) =>

			ss.forEach (child) =>

				match_object = child.val()
				uid = child.key

				@matches[uid] = new Match(match_object, this)
				@match_order.push(match_object)

				false

			@log "retrieval finished. #{ @match_order.length } matches found."
			if callback? then callback(@matches)

	updateStats: =>

		@log "clearing all player statistics..."

		for uid, player of @players
			player.reset_stats()

		@log "calculating player statistics..."

		for uid, match of @matches

			if match.status is Status.VALID

				match.player(0).apply_match(match)
				match.player(1).apply_match(match)

		@log "calculations finished."

		@savePlayers()

	savePlayers: =>

		@log "saving current players to database..."
		for player_uid, player of @players
			@firebase.ref(Ladder.ref_player(@ladder_slug, @season_slug, player_uid)).set(player.db_object())

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
