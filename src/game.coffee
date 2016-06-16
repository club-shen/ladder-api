
Status = require "./status"

# Class for single game in a match.
#
module.exports =
class Game

	match = null # the match this game is a part of
	status = null # the status of the game

	# the following variables will not be null if the game is VALID
	stage = null # the stage used in this game
	characters = [] # the characters used in this game
	winner = null # the winner of the game

	constructor: (game_object, @match) ->

		@reports = game_object.reports

		# analyze game status
		# ===================

		if not @reports?
			@status = Status.PENDING
			return this

		# check if the reports are complete
		for i in [0..1]
			if not @reports[i].stage? or not @reports[i].winner? or not @reports[i].characters?
				@status = Status.PENDING
		# check if both reports are equal
		if @reports[0].stage is @reports[1].stage and
		@reports[0].winner is @reports[1].winner and
		@reports[0].characters[0] is @reports[1].characters[0] and
		@reports[0].characters[1] is @reports[1].characters[1]
			@status = Status.VALID
		else
			# at this point, both reports would have to be complete but not equal, so it's invalid
			@status = Status.INVALID

		# extract information from game
		# =============================

		if @status is Status.VALID
			@winner = @reports[0].winner
			@characters = @reports[0].characters
			@stage = @reports[0].stage

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
