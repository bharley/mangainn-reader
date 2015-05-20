###
  Preamble
###

# Includes
express = require 'express'
hbs     = require 'express-hbs'
q       = require 'q'
http    = require 'q-io/http'
cheerio = require 'cheerio'


# Configuring express
app = express()
app.engine 'hbs', hbs.express4
    defaultLayout: "#{__dirname}/views/layouts/default.hbs"
app.set 'view engine', 'hbs'
app.set 'views', "#{__dirname}/views"


# Some helpful variables
mangainn = 'http://www.mangainn.me/manga/chapter/'


###
  Routes
###

# Landing page
app.get '/', (req, res) ->
  # todo
  res.send ''


# Displays a chapter
app.get '/m/:chapter', (req, res) ->
  # Base URL
  url = mangainn + req.params.chapter

  # Fetch the first image and the number of pages we need
  http.read(url).then (body) ->
    $     = cheerio.load body
    title = $('#gotomangainfo2').text().replace(/^[ -]+/, '')
    pages = [$('#imgPage').attr('src')]
    num   = $('#cmbpages option:last-child').text()
    
    # Fetch each image
    q.all([2..num].map (i) -> http.read(url + "/page_#{i}")).then (bodies) ->
      # Comb through all the promises
      for data in bodies
        $d = cheerio.load data
        pages.push $d('#imgPage').attr('src')

      console.log pages
      res.render 'webtoon', {title, pages}


###
  Server
###

# Server
server = app.listen 3000, ->

  host = server.address().address
  port = server.address().port

  console.log('Mangainn Reader listening at http://%s:%s', host, port)
