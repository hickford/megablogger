zappa = require 'zappa'
port = process.env.PORT || 5000	# 5000 for consistency with foreman's default

mb = zappa.run port, ->
    @enable 'default layout'     # html, head, body, etc
    @use 'zappa'

    io = @io

    @get '/': -> 
        scripts = [ '/socket.io/socket.io', '/zappa/zappa', '/index']#
        io.sockets.emit 'post',{}
        @render 'index': {scripts}

    @view 'index' : ->
        @title = 'socket crash?'
        h1 @title
        p "Stable run locally, crashes when deployed to Heroku"

    # will it crash without connect?
    #@client '/index.js': ->
    #    @connect()


