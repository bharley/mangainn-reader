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
app.get '/c/:chapter', (req, res) ->
  renderWebtoon res, req.params.chapter


# Jump point for the latest chapter of a manga
app.get '/m/:title', (req, res) ->
  # Grab the manga and make sure it exists
  slug = if mangas[req.params.title]?
    mangas[req.params.title].slug
  else
    req.params.title

  # The main manga's url
  url = mangainn + slug

  # Fetch the page listing all of the chapters so we can get the latest one
  http.read(url).then (body) ->
    $          = cheerio.load body
    chapterUrl = $('.content > div:last-child > table > tr:last-child > td:first-child > span > a').attr('href')
    chapter    = chapterUrl.match(new RegExp("^#{mangainn}chapter/(.*)$"))?[1]
    
    # Error out if we didn't get anything
    if not chapter? then res.send "Error fetching latest chapter slug (#{chapterUrl})."

    # Render the latest chapter
    renderWebtoon res, chapter


# Parses out links from MangaInn into something useful
app.get '/q', (req, res) ->
  url = req.query.url

  # First see if we've been sent a link to a specific chapter
  chapter = url.match(new RegExp('^(?:https?://)?(?:www\.)?mangainn\.me/manga/chapter/([^/]+)(?:/page_\\d+)?$'))?[1]
  if chapter then return res.redirect "/c/#{chapter}"

  # See if we were passed a title page
  title = url.match(new RegExp('^(?:https?://)?(?:www\.)?mangainn\.me/manga/([^/]+)$'))?[1]
  if title then return res.redirect "/m/#{title}"

  # I don't understand this link
  res.send 'Unknown link structure'


###
  Helpers
###

renderWebtoon = (res, chapter) ->
  # Base URL
  url = mangainn + 'chapter/' + chapter

  # Fetch the first image and the number of pages we need
  http.read(url).then (body) ->
    $        = cheerio.load body
    title    = $('#gotomangainfo2').text().replace(/^[ -]+/, '')
    pages    = [$('#imgPage').attr('src')]
    num      = $('#cmbpages option:last-child').text()
    previous = $('#chapters option[selected]').prev().val()
    next     = $('#chapters option[selected]').next().val()
    
    # Fetch each image
    q.all([2..num].map (i) -> http.read(url + "/page_#{i}")).then (bodies) ->
      # Comb through all the promises
      for data in bodies
        $d = cheerio.load data
        pages.push $d('#imgPage').attr('src')

      res.render 'webtoon', {title, pages, previous, next}


###
  Server
###

# Server
server = app.listen (process.env.PORT || 3000), ->

  host = server.address().address
  port = server.address().port

  console.log('Mangainn Reader listening at http://%s:%s', host, port)
