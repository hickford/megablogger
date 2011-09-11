zappa = require('zappa')
port = process.env.PORT || 5000	# 5000 for consistency with foreman's default

mb = zappa.run port, ->
    enable 'default layout'     # html, head, body, etc
    #enable 'serve jquery'
    use 'bodyParser'        # for HTTP post 
    def io:io

    mongoose = require('mongoose')
    mongoose.connect(process.env.MONGOLAB_URI || 'mongodb://localhost/mb')  # maybe?
    def quip: mongoose.model('Post',
        new mongoose.Schema({
            text : String,
            date : Date
        })
    )


    get '/': -> 
        @scripts = ['/zappa/zappa', '/socket.io/socket.io', '/mega', '/zappa/jquery']
        quip.find( {}, {}, {limit:20, sort: {$natural: -1}},(err, docs) =>               # double-arrow for scope           
            if !err
                @posts = docs
            render 'index'
        )

    post '/': ->
        if @text
            p = new quip({text: @text, date: new Date})
            p.save()
            io.sockets.emit('post',{post: p})
        redirect '/'   # get

    view 'post' : ->
        li -> @post.text

    view 'new' : ->
        h2 'New post'
        form action:'/', method:'post', ->
            input type:'text', name:'text', placeholder:'new post', autofocus:true, required:true

    view 'index' : ->
        @title = 'Megablogger'
        h1 @title
        partial 'new'
        h2 'Recent posts'
        ul id:'posts', ->
            for p in @posts
                partial 'post', post: p

    client '/mega.js': ->
        connect()
        at post: ->
            # prepend HTMLed post to list of posts
            alert @post.text

