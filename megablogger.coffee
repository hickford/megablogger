zappa = require 'zappa'
port = process.env.PORT || 5000	# 5000 for consistency with foreman's default

mb = zappa.run port, ->
    @enable 'default layout'     # html, head, body, etc
    @enable 'serve jquery'
    @use 'bodyParser'        # for HTTP post 
    @use 'zappa'

    @configure
        development: => @use errorHandler: {dumpExceptions: on}
        production: => @use 'errorHandler'

    @io.configure('production', =>          # looks in environment variable NODE_ENV
        @io.set 'transports', ['xhr-polling']
        @io.set 'polling duration', 10
    )
    io = @io    # make avaliable in handlers

    validator = require 'validator'

    mongoose = require 'mongoose'
    mongoose.connect(process.env.MONGOLAB_URI || 'mongodb://localhost/megablogger')
    quip = mongoose.model('Post',
        new mongoose.Schema({
            text : String,
            date : Date
        })
    )

    @get '/': -> 
        scripts = [ '/socket.io/socket.io', '/zappa/jquery', '/zappa/zappa', '/index']
        stylesheets = ['/index'] 
        quip.find( {}, {}, {limit:21, sort: {$natural: -1}},(err, posts) =>               # double-arrow for scope           
            @render 'index': {posts, scripts, stylesheets}
        )

    @css '/index.css': '''
        #posts li:nth-last-child(even){background-color:white}
        #posts li:nth-last-child(odd){background-color:\#eee}
    '''

    @post '/': ->
        text = @body.text
        if text
            post = new quip({text: validator.sanitize(text).entityEncode(), date: new Date})
            post.save()
            io.sockets.emit 'post',post
        @redirect '/'

    @view 'posts': ->
        ul id:'posts', ->
            for post in @posts
                partial 'post', post: post

    @view 'post' : ->
        li -> @post.text

    @view 'new' : ->
        h2 'New post'
        form id:'new', action:'/', method:'post', ->
            input type:'text', name:'text', placeholder:'new post', autofocus:true, required:true

    @view 'index' : ->
        @title = 'Megablogger'
        h1 @title
        partial 'new'
        h2 'Recent posts'
        partial 'posts'

    @client '/index.js': ->
        @connect()

        @on post: ->
            post = @data
            rendered_post = $('<li>').text("#{post.text}")      # I want to reuse my CoffeeKup @view :/
            rendered_post.prependTo('#posts').hide().slideDown()

