
Elo = require "./elo"
Match = require "./match"

module.exports =
class Player

	user: null

	rating: null
	match_wins: null
	match_losses: null
	total_matches: null

	constructor: (@user, @player_object) ->

		@rating = @player_object.rating
		@match_wins = @player_object.match_wins
		@match_losses = @player_object.match_losses
		@total_matches = @player_object.total_matches

	reset_stats: ->

		@rating = 1500
		@match_wins = 0
		@match_losses = 0
		@total_matches = 0

	apply_match: (match) -> # (uid, other, score, k = 100, floor = 100) ->

		if @user.uid in match.player_uids # this player is involved in this match

			# get k and floor
			k = 100
			floor = 100

			# get the opposing player's UID
			opponent_uid = match.player_uids[+(@user.uid is match.player_uids[0])]
			opponent = match.ladder.getPlayer opponent_uid

			# calculate this player's score first
			if match.winner_uid() is @user.uid
				score = 1
			else
				score = 0

			# calculate the adjusted rating using ELO
			adjusted_rating = Elo.adjust(@rating, opponent.rating, score, k, floor)

			@rating = adjusted_rating

			# set statistics
			if score is 1 then @match_wins++ else @match_losses++
			@total_matches++

	db_object: -> {
		rating: @rating ? 1500
		match_wins: @match_wins ? 0
		match_losses: @match_losses ? 0
		total_matches: @total_matches ? 0
	}
