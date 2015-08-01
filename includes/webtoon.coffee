$ ->
  next = ->
    btn = $('.next-button')
    btn[0].click() if btn.length
  previous = ->
    btn = $('.previous-button')
    btn[0].click() if btn.length

  # -- Arrow navigation
  # Navigate through the chapters based on arrow keys
  document.onkeydown = (e = window.event) ->
    if e.keyCode is 37
      previous()
    else
      next()

  # -- Fancy swipe navigation
  # Record some window properties on resizes
  viewport = desiredDistance = null
  setProps = () ->
    viewport = $(window).width();
    desiredDistance = (if viewport < 400 then 0.35 else 0.25) * viewport
  setProps()
  $(window).resize(_.debounce(setProps, 80))

  # Grab hold of the arrows for later
  $leftArrow = $('.arrow-left')
  $rightArrow = $('.arrow-right')

  # Navigate through the chapters based on swiping
  hammer = new Hammer $('html')[0], ['pan']
  hammer.on 'panleft panright', (ev) ->
    return if not ev

    angle = Math.abs ev.angle
    if angle > 160 || angle < 20
      if not ev.isFinal
        # Animate the pulls
        pullDistance = 1 - Math.min(ev.distance / desiredDistance, 1)
        if pullDistance < 0.9
          if ev.type is 'panleft'
            $rightArrow.css 'right', "-#{pullDistance}em"
            $leftArrow.css  'left',  ''
          else
            $leftArrow.css  'left',  "-#{pullDistance}em"
            $rightArrow.css 'right', ''
      else
        # See if we had a valid touch event
        if ev.distance >= desiredDistance
          if ev.type is 'panleft'
            next()
          else
            previous()
        else
          $rightArrow.css 'right', ''
          $leftArrow.css  'left',  ''
    else
      $rightArrow.css 'right', ''
      $leftArrow.css  'left',  ''
