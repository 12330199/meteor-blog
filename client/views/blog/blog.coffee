getComment = (id)->
  Comment.first slug: Session.get('slug'), sectionId: id

Template.blogShow.rendered = ->

  # Add SideComments
  settings = Blog.settings.comments
  # check if useSideComments config is true (default is null)
  if settings.useSideComments
    SideComments = require 'side-comments'

    # check if config allows anonymous commenters (default is null)
    if settings.allowAnonymous and !Meteor.user()
      commentUser =
        name: 'Anonymous'
        avatarUrl: settings.defaultImg
        id: 0
    else if Meteor.user()
      # check username
      name = if Meteor.user().username then Meteor.user().username else Meteor.user().emails[0].address
      if Meteor.user().profile?[settings.userImg]
        avatar = Meteor.user().profile[settings.userImg]
      else
        avatar = settings.defaultImg
      commentUser =
        name: name
        avatarUrl: avatar
        id: Meteor.userId()
    else
      commentUser =
        name: 'Login to Comment'
        avatarUrl: settings.defaultImg
        id: 0

    # load existing comments
    existingComments = []
    @data.comments.forEach((comment)->
      comment.comment.id = comment._id
      if existingComments[comment.sectionId]
        existingComments[comment.sectionId].comments.push comment.comment
      else
        existingComments[comment.sectionId] =
          sectionId: comment.sectionId.toString()
          comments: [comment.comment]
    )

    # add side comments
    sideComments = new SideComments '#commentable-area', commentUser, existingComments

    # side comments events
    sideComments.on 'commentPosted', (comment) ->
      if settings.allowAnonymous or Meteor.user()
        attrs =
          slug: Session.get('slug')
          sectionId: comment.sectionId
          comment:
            authorAvatarUrl: comment.authorAvatarUrl
            authorName: comment.authorName
            authorId: comment.authorId
            comment: comment.comment
        commentId = Comment.create attrs
        comment.id = commentId
        sideComments.insertComment(comment)
      else
          comment.id = -1
          sideComments.insertComment
            sectionId: comment.sectionId
            authorName: comment.authorName
            comment: 'Please login to post comments'

    sideComments.on 'commentDeleted', (comment) ->
      if Meteor.user()
        Comment.destroyAll comment.id
        sideComments.removeComment comment.sectionId, comment.id

Template.blogShowBody.rendered = ->

  # Hide draft posts from crawlers
  if not @data.post.published
    $('<meta>', { name: 'robots', content: 'noindex,nofollow' }).appendTo 'head'

  $('meta[property^="og:"]').remove()
  $('meta[property^="twitter:"]').remove()

  #
  # OpenGraph tags
  #

  $('<meta>', { property: 'og:type', content: 'article' }).appendTo 'head'
  $('<meta>', { property: 'og:site_name', content: location.hostname }).appendTo 'head'
  $('<meta>', { property: 'og:url', content: location.origin + location.pathname }).appendTo 'head'
  $('<meta>', { property: 'og:title', content: @data.post.title }).appendTo 'head'
  $('<meta>', { property: 'og:description', content: @data.post.excerpt }).appendTo 'head'

  img = @data.post.thumbnail()
  if img
    if not /^http(s?):\/\/+/.test(img)
      img = location.origin + img
    $('<meta>', { property: 'og:image', content: img }).appendTo 'head'

  #
  # Twitter cards
  #

  $('<meta>', { property: 'twitter:card', content: 'summary' }).appendTo 'head'
  # What should go here?
  #$('<meta>', { property: 'twitter:site', content: '' }).appendTo 'head'

  author = @data.post.author()
  if author.profile and author.profile.twitter
    $('<meta>', { property: 'twitter:creator', content: author.profile.twitter }).appendTo 'head'

  if author.profile and author.profile.profileUrl
    $('<link>', { href: author.profile.profileUrl, rel: 'author' }).appendTo 'head'

  $('<meta>', { property: 'twitter:url', content: location.origin + location.pathname }).appendTo 'head'
  $('<meta>', { property: 'twitter:title', content: @data.post.title }).appendTo 'head'
  $('<meta>', { property: 'twitter:description', content: @data.post.excerpt }).appendTo 'head'
  $('<meta>', { property: 'twitter:image:src', content: img }).appendTo 'head'

  #
  # Twitter share button
  #

  base = "https://twitter.com/intent/tweet"
  url = encodeURIComponent location.origin + location.pathname
  text = encodeURIComponent @data.post.title
  href = base + "?url=" + url + "&text=" + text

  if author.profile and author.profile.twitter
    href += "&via=" + author.profile.twitter

  $(".tw-share").attr "href", href

  #
  # Facebook share button
  #

  base = "https://www.facebook.com/sharer/sharer.php"
  url = encodeURIComponent location.origin + location.pathname
  title = encodeURIComponent @data.post.title
  summary = encodeURIComponent @data.post.excerpt
  href = base + "?s=100&p[url]=" + url + "&p[title]=" + title + "&p[summary]=" + summary

  if img
    href += "&p[images][0]=" + encodeURIComponent img

  $(".fb-share").attr "href", href
