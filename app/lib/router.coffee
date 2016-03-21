Router.configure
  layoutTemplate: "layout"
  loadingTemplate: "loading"
  notFoundTemplate: "not_found"
  i18n:
    exclude: [
      '\/admin', '\/img\/', '\/reset-password'
    ]
    server:
      exclude:
        sitemap: '^\/sitemap\.xml'


#if Meteor.isClient
#  AccountsEntry.config
#    homeRoute: '/home' #redirect to this path after sign-out
#    dashboardRoute: '/home'  #redirect to this path after sign-in
#    passwordSignupFields: 'EMAIL_ONLY'

if Meteor.isClient
  Router.onAfterAction ->
    Meteor.Piwik.trackPage(Router.current().route.path(this))


Router.route '/',
  name: 'smartervote'
  layoutTemplate: 'layoutSmartervote'
  waitOn: ->
    [
      Meteor.subscribe('questions', TAPi18n.getLanguage())
      Meteor.subscribe('visits')
      Meteor.subscribe('answers')
      Meteor.subscribe('publishedVisits')
    ]
  action: ->
    @render 'smartervote'

Router.route 'myBubbles/:id',
  waitOn: ->
    #TODO denormalise proPercent into visit
    Meteor.subscribe('visitAndAnswers', @params.id)
  data: ->
    Visits.findOne(@params.id)
  seo:
    image: -> 
      Meteor.absoluteUrl().slice(0, -1)+@data().myBubblesUrl
  action: ->
    @render 'myBubbles'

Router.route 'smartervote-content',
  waitOn: ->
    Meteor.subscribe('questions', TAPi18n.getLanguage())
  action: ->
    @render 'questionOverview'

#admin routes
Router.route '/admin/users',
  waitOn: ->
    Meteor.subscribe('registeredUsers')
  action: ->
    @render 'users'

Router.route '/admin/editQuestions',
  waitOn: ->
    Meteor.subscribe('questions', TAPi18n.getLanguage())
  action: ->
    @render 'editQuestions'

Router.route '/admin/cnc',
  waitOn: ->
    Meteor.subscribe('questions', TAPi18n.getLanguage())
  action: ->
    @render 'cnc'

Router.route '/admin/smartervote',
  waitOn: ->
    Meteor.subscribe('visitsOfRegisteredUsers')
  action: ->
    @render 'smartervoteAdmin'

Router.route '/account',
  action: ->
    @render 'account'
