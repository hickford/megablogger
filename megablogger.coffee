zappa = require('zappa')
port = process.env.PORT || 5000	# 5000 for consistency with foreman's default

mb = zappa.run port, ->
    @enable 'default layout'     # html, head, body, etc
    @enable 'serve jquery'
    @use 'bodyParser'        # for HTTP post 
    validator = require('validator')

    mongoose = require('mongoose')
    mongoose.connect(process.env.MONGOLAB_URI || 'mongodb://localhost/mb')  # maybe?
    quip = mongoose.model('Post',
        new mongoose.Schema({
            text : String,
            date : Date
        })
    )

    @get '/': -> 
        scripts = ['/zappa/zappa', '/socket.io/socket.io', '/mega', '/zappa/jquery']
        #console.log(@query)
        quip.find( {}, {}, {limit:20, sort: {$natural: -1}},(err, posts) =>               # double-arrow for scope           
            @render 'index': {posts, scripts}
        )

    @post '/': ->
        console.log(@body)
        text = @body.text
        if text
            p = new quip({text: validator.sanitize(text).entityEncode(), date: new Date})
            p.save()
            #@io.sockets.emit('post',{post: p})
        @redirect '/'   

    @view 'posts': ->
        ul id:'posts', ->
            for post in @posts
                partial 'post', post: post

    @view 'post' : ->
        li -> @post.text

    @view 'new' : ->
        h2 'New post'
        form action:'/', method:'post', ->
            input type:'text', name:'text', placeholder:'new post', autofocus:true, required:true

    @view 'index' : ->
        @title = 'Megablogger'
        h1 @title
        partial 'new'
        h2 'Recent posts'
        partial 'posts'

    @client '/mega.js': ->
        connect()
        @on post: ->
            # prepend HTMLed post to list of posts
            alert (@post.text)
            $('#posts').prepend(@post.text)

