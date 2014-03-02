
BLOCK_SIZE = 64 * 16 * 1024 # use for sha1 the file

player = null

###
if (typeof File isnt "undefined") and not File::slice
  File::slice = File::webkitSlice  if File::webkitSlice
  File::slice = File::mozSlice  if File::mozSlice
###

sha1Stream = (input) ->
  blocksize = 512
  h = naked_sha1_head()
  i = 0
  while i < input.length
    len = Math.min(blocksize, input.length - i)
    block = input.substr(i, len)
    naked_sha1(str2binb(block), len * chrsz, h)
    i += blocksize
  return binb2hex(naked_sha1_tail(h))


processFile = (file) ->
  reader = new FileReader()

  ###
  onProgress = (event) ->
    if event['total'] == 0
      percentLoaded = 0
    else
      percentLoaded = Math.round((event['loaded'] / event['total']) * 100)
    console.log percentLoaded

  #update precentage while file reading
  reader.onprogress = onProgress
  ###

  step = 0
  file_sha1 =
    head: ""
    body: ""
    tail: ""

  onLoadEnd = (event) ->
    result = sha1Stream(event.target.result)
    if step == 0
      file_sha1.head = result
      mid = Math.floor( (file.size - BLOCK_SIZE) / 2)
      reader.readAsBinaryString file.slice(mid, mid+BLOCK_SIZE)
      step = 1
    else if step == 1
      file_sha1.body = result
      reader.readAsBinaryString file.slice(file.size - BLOCK_SIZE, file.size)
      step = 2
    else if step == 2
      file_sha1.tail = result
      onFinish()
    else if step == 3
        file_sha1.head = result
        file_sha1.body = result
        file_sha1.tail = result
        onFinish()

  #reading finish, do sha1 calcuate.
  reader.onloadend = onLoadEnd
  if file.size > BLOCK_SIZE
    reader.readAsBinaryString file.slice(0, BLOCK_SIZE)
  else
    step = 3
    reader.readAsBinaryString file.slice(0, BLOCK_SIZE)

  # reader.readAsArrayBuffer(file)
  # use ArrayBuffer is considered to be more approprate.

  onFinish = ->
    console.log file_sha1
    startPlayer(file)


player_started = false
video_unsupported = () ->
  if not player_started
    alert "Video is not started. Maybe it is not supported"

onPlayerPlaying = ->
  # start playing
  player_started = true

startPlayer = (file) ->
  URL = window['URL']
  fileUrl = URL.createObjectURL(file)
  console.log player.canPlayType(file.type)
  player.addEventListener("playing", onPlayerPlaying)

  player.src = fileUrl

  setTimeout(video_unsupported, 500)
  player.play()

$(document).ready ->
  $drop_here = $('#drop-here')
  player = document.getElementById("player")

  onDragover = (e) ->
    e.preventDefault()
    e.stopPropagation()
    $drop_here.addClass('drag')

  $drop_here.on('dragover', onDragover)

  onDragend = (e) ->
    e.preventDefault()
    e.stopPropagation()
    $drop_here.removeClass('drag')

  $drop_here.on('dragend', onDragend)

  onDrop = (e) ->
    console.log 'here'
    $drop_here.removeClass('drag')
    e.preventDefault()
    e.stopPropagation()
    if not e.originalEvent.dataTransfer
      return
    file = e.originalEvent.dataTransfer.files[0];
    console.log file
    processFile(file)

  $drop_here.on('drop', onDrop)