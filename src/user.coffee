
module.exports =
class User

	display_name: null
	email: null
	name: null

	constructor: (@uid, user_object) ->

		if user_object?
			@display_name = user_object.displayName
			@email = user_object.email
			@name = user_object.name
		else
			@display_name = @uid
			@email = ""
			@name = @uid
