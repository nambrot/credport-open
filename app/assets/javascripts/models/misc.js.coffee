class @Recommendation extends Backbone.Model
	initialize: (options) ->
		@user = options.user
	relationship_context_mapping:
	  'credport_friend_recommendation': 'a friend'
	  'credport_colleague_recommendation': 'a colleague'
	  'credport_family_recommendation': 'a family member'
	  'credport_other_recommendation': 'an acquitance'
	get_relationship: ->
		@relationship_context_mapping[@get('role')]

class @Recommendations extends Backbone.Collection
	initialize: (collection, options) ->
		@user = options.user
	model: Recommendation

class @Verification extends Backbone.Model
	
class @VerificationCollection extends Backbone.Collection
	model: Verification
	parse: (resp, xhr) -> 
		resp.data.identities.concat resp.data.real

class @EducationAttribute extends Backbone.Model
	toggleVisibility: ->
		$.post "/educationattribute/#{@get('id')}/#{!@get('visible')}",{}, (resp) =>
			@set resp.education_attribute
			if @get('visible')
				$.gritter.add title: "Success", text: "Education shown", time: 1000
			else
				$.gritter.add title: "Success", text: "Education hidden", time: 1000
class @EducationHistory extends Backbone.Collection
	model: EducationAttribute

class @WorkAttribute extends Backbone.Model
	toggleVisibility: ->
		$.post "/workattribute/#{@get('id')}/#{!@get('visible')}",{}, (resp) =>
			@set resp.work_attribute
			if @get('visible')
				$.gritter.add title: "Success", text: "Work shown", time: 1000
			else
				$.gritter.add title: "Success", text: "Work hidden", time: 1000
class @WorkHistory extends Backbone.Collection
	model: WorkAttribute
class @Review extends Backbone.Model
	review: ->
		@get('connections')[0].attributes.text
	by: -> 
		new Identity @get('nodes')[0]
class @Reviews extends Backbone.Collection
	model: Review
class @Identity extends Backbone.Model

class @Path extends Backbone.Model
	nodes: ->
		if !@nodesobject?
			@nodesobject = _.map @get('nodes'), (node) ->
				new Identity(node)
		@nodesobject
	connections: ->
		@get('connections')
			
class @CommonConnections extends Backbone.Collection
	model: Path
	parse: (resp, xhr) -> 
		resp.data
		
class @CommonInterests extends Backbone.Collection
	model: Path
	parse: (resp, xhr) -> 
		resp.data

class @Email extends Backbone.Model

class @Phone extends Backbone.Model

class @Emails extends Backbone.Collection
	model: Email

class @Phones extends Backbone.Collection
	model: Phone

class @Website extends Backbone.Model

class @Websites extends Backbone.Collection
	model: Website