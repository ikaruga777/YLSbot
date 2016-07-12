
module.exports = (robot) ->

  yaml =require('js-yaml')
  fs   = require('fs')
  doc = yaml.load(fs.readFileSync('./settings/tasks.yaml', 'utf8'))



  INNER = 1
  OUTER = -1
  TEAMS_INITIALIZER =
    'red':
      direction:INNER
      station: 0
    'blue':
      direction:OUTER
      station:0

  STATIONS = ['大崎','品川','田町','浜松町','新橋','有楽町',
              '東京','神田','秋葉原','御徒町','上野','鶯谷',
              '日暮里','西日暮里','田端','駒込','巣鴨','大塚',
              '池袋','目白','高田馬場','新大久保','新宿','代々木',
              '原宿','渋谷','恵比寿','目黒','五反田']

  getStrageValue = (key) ->
    robot.brain.get(key)

  setStrageValue = (key,value) ->
    robot.brain.set(key,value)

  robot.enter (res) ->
    setStrageValue('YLS_TEAMS',JSON.stringify(TEAMS_INITIALIZER))
    res.send("HI")

  robot.hear /init ([0-9]+)/i,(res) ->
    setStrageValue('YLS_TEAMS',JSON.stringify(TEAMS_INITIALIZER))

  # 駅移動
  move = (team,dice)->
    nextPosition = (parseInt(team.station or 0,10) + (dice * team.direction) )% STATIONS.length
    if nextPosition < 0
      nextPosition = STATIONS.length + nextPosition
    nextPosition

  # チームの現在地を教えてくれる
  robot.hear /now (\w+)/i,(res) ->
    team = JSON.parse(getStrageValue('YLS_TEAMS'))[res.match[1]]
    console.log(team)
    message = "チーム#{res.match[1]}は今#{STATIONS[team.station]}にいます"
    res.send(message)

  # サイコロをふる。
  robot.hear /roll (\w+)/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    nowStation = teams[res.match[1]].station
    dice = Math.floor( Math.random()*6 )+1
    nextStation = move(teams[res.match[1]], dice)
    message = "#{STATIONS[nowStation]}にいるチーム#{res.match[1]}は\n"
    message +="#{dice}がでたので,#{STATIONS[nextStation]}に移動して下さい。"
    res.send(message)
    teams[res.match[1]].station = nextStation
    console.log(teams)
    setStrageValue('YLS_TEAMS',JSON.stringify(teams))
