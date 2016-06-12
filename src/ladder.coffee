
# Class for ELO-related utility functions.
#
class Elo

	constructor: () ->

	@adjust: (rating, other, score, k = 0, floor = 0) ->
		expected = @expectedScore(rating, other)
		return Math.max(floor, Math.round(rating + k * (score - expected)))

	# An ELO function for calculating expected score based on rating difference,
	# which is a number between 0 - 1. If other is null, then rating will be
	# used as the difference.
	#
	# @param {Number} rating the rating of the first player, or the difference if other doesn't exist
	# @param {Number} other the rating of the second player
	# @return the expected score of the player
	@expectedScore: (rating, other) ->
		diff = if other then other - rating else rating
		return 1 / (1 + Math.pow(10, diff / 400))

class Rankings

	constructor: ->

	@createProfile: (uid) ->
		ref = db.ref("ladders/smash-4/users/#{uid}")
		ref.once("value", (snapshot) ->
			if(!snapshot.val())
				ref.set({
					elo: 1500
					wins: 0
					losses: 0
					matches: []
				}).then(->
					console.log "Created Ranking Profile for UID: " + uid
				).catch((error) ->
					console.log "Failed trying to create Ranking Profile for UID: " + uid + ", " + error.message
				)
		)

# Enumeration for match status.
#
class MatchStatus

	constructor: ->

	@VALID: 0
	@PENDING: 1
	@INVALID: 2

# Class for single game in a match.
#
class Game

	match: null # the match this game is a part of
	status: null # the status of the game

	# the following variables will not be null if the game is VALID
	stage: null # the stage used in this game
	characters: [] # the characters used in this game
	winner: null # the winner of the game

	constructor: (game, @match) ->
		# analyze game status
		# ===================

		# check if the reports are complete
		for i in [0..1]
			if not report(i).stage? or not report(i).winner? or not report(i).characters?
				@status = MatchStatus.PENDING
		# check if both reports are equal
		if report(0).stage is report(1).stage and
		report(0).winner is report(1).winner and
		report(0).characters[0] is report(1).characters[0] and
		report(0).characters[1] is report(1).characters[1]
			@status = MatchStatus.VALID

		# at this point, both reports would have to be complete but not equal, so it's invalid
		@status = MatchStatus.INVALID

		# extract information from game
		# =============================

		if @status is MatchStatus.VALID
			@winner = report(0).winner
			@characters = report(0).characters
			@stage = report(0).stage

	report: (i) -> game.reports[i]

	toElement: () -> """
		<div class="game">
			<span class="winner winner--#{ @winner }"></span>
		</div>
	"""

	@emptyElement: () -> """
		<div class="game">
			<span class="winner winner--empty"></span>
		</div>
	"""

	@nullElement: () -> """
		<div class="game">
			<span class="winner winner--null"></span>
		</div>
	"""

# A class representing a match.
#
class Match

	@createList: (matchArray) ->
		matches = []
		for i, v of @matchArray
			matches.push(new Match(i, v))
		return matches

	constructor: (@id, match) ->
		games = []
		for i, game of match.games
			games.push(new Game(game, match))

		@set = match.set
		@time = match.time
		@status = MatchStatus.PENDING

		if match.set != 3 && match.set != 5
			console.log "[WARNING] match #{mid} has an invalid set number #{match.set}, so we'll assume it's 3"
			match.set = 3

		if match.players.length != 2
			console.log "[ERROR] This match has an invalid number of players (need 2, but found #{match.players.length})"
			@status = MatchStatus.INVALID

		for game in games
			if game.status is MatchStatus.INVALID or game.status is MatchStatus.PENDING
				@status = game.status
				break

		if @status isnt MatchStatus.INVALID
			wins = [0, 0]
			@stages = []
			@characters = [[], []]

			for i, game of games
				if game.winner is 0 then wins[0]++
				if game.winner is 1 then wins[1]++

				@stages.push game.stage
				@characters[0].push game.characters[0]
				@characters[1].push game.characters[1]

			if @set is 3 and wins[0] >= 2 or @set is 5 and wins[0] >= 3
				@winner = 0
				break

			if @set is 3 and wins[1] >= 2 or @set is 5 and wins[1] >= 3
				@winner = 1
				break

	player: (i) -> match.players[i]

	challenger: -> @player 0
	defender: -> @player 1

	game: (i) -> games[i]

	setCount: -> match.set

	gameCount: -> games.length

	winner: ->
		if @status() != 0 then return null
		winners = {
			0: 0
			1: 0
		}
		for game in @games
			winners[game.winner()]++
		if(winners[0] >= 2) then return 0
		if(winners[1] >= 2) then return 1
		return null

	winnerName: () -> return @player(@winner())

	toElement: () ->
		el = """
			<div class="match">
				<div class="match--title">
					<span class="player player--0">#{ @player(0) }</span>vs<span class="player player--1">#{ @player(1) }</span>
				</div><div class="match--games">
		"""
		for i in [@setCount()-1...-1] by -1
			if i < @games.length
				el += @games[i].toElement()
			else
				el += Game.nullElement()
		el += """
				</div>
			</div>
		"""
		return el
