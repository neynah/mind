# Abstract class.
class Discussion.OneComponent extends UIComponent
  onCreated: ->
    super

    @currentDiscussionId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      discussionId = @currentDiscussionId()
      @subscribe 'Discussion.one', discussionId if discussionId

    @autorun (computation) =>
      return unless @subscriptionsReady()

      discussion = Discussion.documents.findOne @currentDiscussionId(),
        fields:
          title: 1

      if discussion
        share.PageTitle discussion.title
      else
        share.PageTitle "Not found"

    @canEdit = new ComputedField =>
      @discussion() and (User.hasPermission(User.PERMISSIONS.DISCUSSION_UPDATE) or (User.hasPermission(User.PERMISSIONS.DISCUSSION_UPDATE_OWN) and (Meteor.userId() is @discussion().author._id)))

  discussion: ->
    Discussion.documents.findOne @currentDiscussionId()

  notFound: ->
    @subscriptionsReady() and not @discussion()
