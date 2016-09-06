# A class for Elo-related calculations. All calculations should be 1:1 with
# the definition of Elo rating calculations, before any of the modifications
# we put on it.
#
module.exports = class Elo

	constructor: ->

	# Calculates the rating adjustment from the player's
	# current rating, the opponent's rating, score, and the constant K.
	#
	# Score can be any number ranging from 0 to 1, but in most cases it's
	# either 0 _or_ 1 (did the player win or lose?). Use 0.5 as the score to
	# signify a draw.
	#
	# K is the maximum rating coefficient for any given match. For example, if
	# K = 40 (the base K of chess rankings) and the rating difference
	# between two players is great (the expected score for either player is ~1 or 0),
	# then the most their rating their change will be 40.
	#
	# If a floor rating is defined, then the rating adjustment will never drop a player's
	# rating below that value.
	#
	# @param {Number} rating the rating of the player
	# @param {Number} rc the rating of the opponent
	# @param {Number} score the score of the player (from 0 to 1)
	# @param {Number} k the rating coefficient
	# @param {Number} floor the rating floor
	@adjust: (rating, rc, score, k = 40, floor = 0) ->
		expected = @expectedScore(rating, rc)
		return Math.max(floor, Math.round(rating + k * (score - expected)))

	# Calculates the expected score based on the rating difference between two players,
	# which is a number between 0 - 1. If other is null, then rating will be
	# used as the difference.
	#
	# @param {Number} rating the rating of the player, or the difference if the second parameter is not used
	# @param {Number} other the rating of the opponent
	# @return the expected score of the player
	@expectedScore: (rating, rc) ->
		diff = if rc? then rc - rating else rating
		return 1 / (1 + Math.pow(10, diff / 400))
