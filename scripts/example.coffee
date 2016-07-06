
module.exports = (robot) ->
  POSITION = 'position'

  getStrageValue = (key) ->
    robot.brain.get(key)

  setStrageValue = (key,value) ->
    robot.brain.set(key,value)

  robot.enter (res) ->
    res.send("HI")
    getStrageValue(POSITION) or {}

  robot.hear /init ([0-9]+)/i,(res) ->
    setStrageValue(POSITION, res.match[1])


  STATIONS = ['大崎','品川','田町','浜松町','新橋','有楽町',
              '東京','神田','秋葉原','御徒町','上野','鶯谷',
              '日暮里','西日暮里','田端','駒込','巣鴨','大塚',
              '池袋','目白','高田馬場','新大久保','新宿','代々木',
              '原宿','渋谷','恵比寿','目黒','五反田']

  INNER = 1
  OUTER = -1
  TEAMS = {
    name: 'red'
    direction: OUTER
    station: 0
  }

  # つぎの駅とお題を返す
  move = (dice,team)->
    nextPosition = (parseInt(getStrageValue(POSITION) or 0,10) + (dice * team.direction) )% STATIONS.length
    if nextPosition < 0
      nextPosition = STATIONS.length + nextPosition
    setStrageValue(POSITION, nextPosition)
    console.log(nextPosition)
    console.log(STATIONS.length)
    STATIONS[nextPosition]

  robot.hear /now/i,(res) ->
    message = "今あなたは#{STATIONS[getStrageValue(POSITION)]}にいるよ"
    res.send(message)


  robot.hear /roll/i,(res) ->
    nowStation = STATIONS[getStrageValue(POSITION)]
    dice = Math.floor( Math.random()*6 )+1
    nextStation = move(dice,TEAMS)
    message = "#{nowStation}にいるちーむ、#{dice}がでたので,#{nextStation}に着陸"
    res.send(message)
