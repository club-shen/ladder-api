# Class for ELO-related utility functions.
#
module.exports = class Elo

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
