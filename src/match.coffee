
Status = require "./status"
Game = require "./game"

module.exports =
class Match

	games: null   # the array of Game objects
	set: null     # the match set amount (either 3 or 5)
	time: null    # the timestamp of which this match was created
	status: null  # the status of the match
	player_uids: null # the array of Player objects involved in this match

	@createList: (matchArray) ->
		matches = []
		for i, v of matchArray
			matches.push(new Match(i, v))
		return matches

	constructor: (match_object, @ladder) ->

		@games = []
		for i, game_object of match_object.games
			@games.push(new Game(game_object, match_object))

		@set = match_object.set
		@time = match_object.time
		@status = Status.PENDING
		@player_uids = match_object.players

		if match_object.set != 3 && match_object.set != 5
			console.log "[WARNING] match #{mid} has an invalid set number #{match_object.set}, so we'll assume it's 3"
			match_object.set = 3

		if match_object.players.length != 2
			console.log "[ERROR] This match has an invalid number of players (need 2, but found #{match_object.players.length})"
			@status = Status.INVALID

		for game in @games
			if game.status is Status.INVALID or game.status is Status.PENDING
				@status = game.status
				break

		if @status isnt Status.INVALID
			wins = [0, 0]
			@stages = []
			@characters = [[], []]

			for i, game of @games
				if game.winner is 0 then wins[0]++
				if game.winner is 1 then wins[1]++

				@stages.push game.stage
				@characters[0].push game.characters[0]
				@characters[1].push game.characters[1]

			if @set is 3 and wins[0] >= 2 or @set is 5 and wins[0] >= 3
				@winner = 0
				@status = Status.VALID

			if @set is 3 and wins[1] >= 2 or @set is 5 and wins[1] >= 3
				@winner = 1
				@status = Status.VALID

	player: (i) -> @ladder.getPlayer @player_uids[i]

	challenger: -> @player 0
	defender: -> @player 1

	game: (i) -> @games[i]

	setCount: -> @set

	winner_uid: -> @player_uids[@winner]

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
