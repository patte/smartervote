_numQuestions = new ReactiveVar(0)
_questionIndex = new ReactiveVar(0)
Template.questionNetwork.created = ->
  self = @
  @autorun ->
    _numQuestions.set Questions.find().count()


Template.questionNetwork.rendered = ->
  network = new Network("#bubbles")

  #jump to question, when clicking on node
  network.onNodeClick (d) ->
    _questionIndex.set d.qIndex
    
  width = network.width()
  height = network.height()

  #get clusters from questions
  clusterIndices = {}
  i = 0
  Questions.find().forEach (q) ->
    clusterIndices[q.cluster] ?= []
    clusterIndices[q.cluster].push i
    i+=4
    return

  #draw cluster nodes
  numClusters = Object.keys(clusterIndices).length
  i = 0
  w = width-80
  Object.keys(clusterIndices).forEach (c) ->
    x = 40 + w/numClusters*i
    network.addNode
      id: c+'_max'
      fixed: true
      x: x
      y: 20
      radius: 0
    network.addNode
      id: c+'_min'
      fixed: true
      x: x
      y: height-20
      radius: 0
    i+=1

  #DRY
  selectedVisitId = Session.get 'selectedVisitId'
  if selectedVisitId?
    v = Visits.findOne selectedVisitId
  else
    v = Visits.findOne {},
      sort: {createdAt: -1, limit: 1}

  rScale = d3.scale.linear()
  rScale.domain [0, 0.5]
  rScale.range [20, 70]

  linkDistanceMax = 600
  linkDistanceScale = d3.scale.linear()
  linkDistanceScale.domain [-0.5, 0.5]
  linkDistanceScale.range [0, linkDistanceMax]

  color = d3.scale.category20b()
  Answers.find
    visitId: v._id
  .observe
    added: (answer) ->
      question = Questions.findOne answer.questionId
      value = answer.value
      if question.type is 'boolean'
        value = -0.5 if !answer.value
        value = 0.5 if answer.value
      node =
        id: question._id
        qIndex: question.index
        answerValue: value
        x: width
        y: height/2
        radius: rScale( Math.abs(value) )
        color: d3.rgb(color(clusterIndices[question.cluster])).brighter(value)
      network.addNode node

      ldMin = linkDistanceScale(value)
      network.addLink
        sourceId: node.id
        targetId: question.cluster+'_min'
        linkDistance: ldMin
      network.addLink
        sourceId: node.id
        targetId: question.cluster+'_max'
        linkDistance: linkDistanceMax-ldMin

    changed: (answer) ->
      question = Questions.findOne answer.questionId
      value = answer.value
      if question.type is 'boolean'
        value = -0.5 if !answer.value
        value = 0.5 if answer.value
      network.changeNode
        id: question._id
        answerValue: value
        radius: rScale( Math.abs(value) )
        color: d3.rgb(color(clusterIndices[question.cluster])).brighter(value)

      ldMin = linkDistanceScale(value)
      network.changeLink
        sourceId: question._id
        targetId: question.cluster+'_min'
        linkDistance: ldMin
      network.changeLink
        sourceId: question._id
        targetId: question.cluster+'_max'
        linkDistance: linkDistanceMax-ldMin

    removed: (answer) ->
      question = Questions.findOne answer.questionId
      if question?
        network.removeNode question._id
      else
        network.removeAllLinks
        network.removeAllNodes

  # draw links from cluster to it's questions/answers
  #Object.keys(clusters).forEach (c) ->
  #  clusters[c].forEach (q) ->
  #    network.addLink
  #      sourceId: q.id
  #      targetId: c
  #      value: 1

Template.questionNetwork.helpers
  visit: ->
    selectedVisitId = Session.get 'selectedVisitId'
    if selectedVisitId?
      v = Visits.findOne selectedVisitId
    else
      v = Visits.findOne {},
        sort: {createdAt: -1, limit: 1}
    #console.log "visitId: #{v._id}" if v?
    return v.scoredDoc() if v?
    null

  hasAnswers: ->
    @visit? and @visit.numAnswered > 0

  question: ->
    Questions.findOne
      index: _questionIndex.get()

  answerForQuestion: (visitId, questionId) ->
    return null if !visitId?
    Answers.findOne
      visitId: visitId
      questionId: questionId


Template.scaleQuestion.rendered = ->
  question = @data.question
  @$('.nouislider').noUiSlider(
    start: question.start
    range:
      min: question.min
      max: question.max
  )
  return

Template.scaleQuestion.events
  'slide': (evt, tmpl, val) ->
    a = @answer || {}
    a.visitId = @visit._id
    a.questionId = @question._id
    a.value = parseFloat(val)
    Meteor.call "upsertAnswer", a, (error) ->
      throwError error if error?


Template.booleanQuestion.helpers
  activeCSS: (bool) ->
    "active" if bool is @answer.value

Template.booleanQuestion.events
  'click button': (evt, tmpl, val) ->
    event.target.blur()
    a = @answer || {}
    a.visitId = @visit._id
    a.questionId = @question._id
    a.value = tmpl.$(evt.target).hasClass("yes")
    Meteor.call "upsertAnswer", a, (error) ->
      throwError error if error?
