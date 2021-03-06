Meteor.methods
  'Discussion.new': (document) ->
    check document,
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    throw new Meteor.Error 'unauthorized', "Unauthorized." unless User.hasPermission User.PERMISSIONS.DISCUSSION_NEW

    document.description = Discussion.sanitize.sanitizeHTML document.description

    if Meteor.isServer
      $root = cheerio.load(document.description).root()
    else
      $root = $('<div/>').append($.parseHTML(document.description))

    descriptionText = $root.text()

    check descriptionText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure').length

    descriptionDisplay = Discussion.sanitizeForDisplay.sanitizeHTML document.description

    attachments = Discussion.extractAttachments document.description

    createdAt = new Date()
    documentId = Discussion.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      lastActivity: createdAt
      author: user.getReference()
      title: document.title
      description: document.description
      descriptionDisplay: descriptionDisplay
      descriptionAttachments: ({_id} for _id in attachments)
      changes: [
        updatedAt: createdAt
        author: user.getReference()
        title: document.title
        description: document.description
      ]
      meetings: []

    assert documentId

    StorageFile.documents.update
      _id:
        $in: attachments
    ,
      $set:
        active: true
    ,
      multi: true

    documentId

  'Discussion.update': (document) ->
    check document,
      _id: Match.DocumentId
      title: Match.NonEmptyString
      description: Match.NonEmptyString

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    document.description = Discussion.sanitize.sanitizeHTML document.description

    if Meteor.isServer
      $root = cheerio.load(document.description).root()
    else
      $root = $('<div/>').append($.parseHTML(document.description))

    descriptionText = $root.text()

    check descriptionText, Match.OneOf Match.NonEmptyString, Match.Where ->
      $root.has('figure').length

    descriptionDisplay = Discussion.sanitizeForDisplay.sanitizeHTML document.description

    attachments = Discussion.extractAttachments document.description

    if User.hasPermission User.PERMISSIONS.DISCUSSION_UPDATE
      permissionCheck = {}
    else if User.hasPermission User.PERMISSIONS.DISCUSSION_UPDATE_OWN
      permissionCheck =
        'author._id': user._id
    else
      permissionCheck =
        # TODO: Find a better "no-match" query.
        $and: [
          _id: 'a'
        ,
          _id: 'b'
        ]

    updatedAt = new Date()
    changed = Discussion.documents.update _.extend(permissionCheck,
      _id: document._id
      $or: [
        title:
          $ne: document.title
      ,
        description:
          $ne: document.description
      ]
    ),
      $set:
        updatedAt: updatedAt
        title: document.title
        description: document.description
        descriptionDisplay: descriptionDisplay
        descriptionAttachments: ({_id} for _id in attachments)
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          title: document.title
          description: document.description

    if changed
      StorageFile.documents.update
        _id:
          $in: attachments
      ,
        $set:
          active: true
      ,
        multi: true

    changed
