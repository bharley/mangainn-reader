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
mangainn = 'http://www.mangainn.me/manga/'
mangas = # Poor man's database
  magician:
    title: 'Magician'
    slug:  '783_magician'
  noblesse:
    title: 'Noblesse'
    slug:  '1992_noblesse'

###
  Routes
###

# Jump list to some mangas I care about
app.get '/', (req, res) ->
  res.render 'index', {mangas}


# Displays a chapter
app.get '/m/:chapter', (req, res) ->
  renderWebtoon res, req.params.chapter


# Jump point for the latest chapter of a manga
app.get '/:title', (req, res) ->
  # Grab the manga and make sure it exists
  manga = mangas[req.params.title]
  if not manga? then res.send 'Not found'

  # The main manga's url
  url = mangainn + manga.slug

  # Fetch the page listing all of the chapters so we can get the latest one
  http.read(url).then (body) ->
    $           = cheerio.load body
    chapterUrl  = $('.content > div:last-child > table > tr:last-child > td:first-child > span > a').attr('href')
    chapter     = chapterUrl.match(new RegExp("^#{mangainn}chapter/(.*)$"))?[1]
    
    # Error out if we didn't get anything
    if not chapter? then res.send "Error fetching latest chapter slug (#{chapterUrl})."

    # Render the latest chapter
    renderWebtoon res, chapter


###
  Helpers
###

renderWebtoon = (res, chapter) ->
  # Base URL
  url = mangainn + 'chapter/' + chapter

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

      res.render 'webtoon', {title, pages}


###
  Server
###

# Server
server = app.listen (process.env.PORT || 3000), ->

  host = server.address().address
  port = server.address().port

  console.log('Mangainn Reader listening at http://%s:%s', host, port)
