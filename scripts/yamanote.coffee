# YamanoteLineSugoroku Organizer
# Commands:
# init
# now
# roll
# reverse

module.exports = (robot) ->
  yaml =require('js-yaml')
  fs   = require('fs')
  STATIONS_YAML = yaml.load(fs.readFileSync('./settings/tasks.yaml', 'utf8'))
  INNER = 1
  OUTER = -1
  TEAMS_INITIALIZER =
    'red':
      direction:INNER
      station: 0
    'blue':
      direction:OUTER
      station:0

  getStrageValue = (key) ->
    robot.brain.get(key)

  setStrageValue = (key,value) ->
    robot.brain.set(key,value)

  robot.enter (res) ->
    setStrageValue('YLS_TEAMS',JSON.stringify(TEAMS_INITIALIZER))
    res.send("HI")

  robot.hear /init ([0-9]+)/i,(res) ->
    setStrageValue('YLS_TEAMS',JSON.stringify(TEAMS_INITIALIZER))

  # ランダム
  getRandom = (max)->
    Math.floor( Math.random()* max)

  # 駅移動
  move = (team,dice)->
    origin = parseInt(team.station or 0,10)
    # 循環させるために駅数のあまり
    dest = (origin + (dice * team.direction) )% STATIONS_YAML.length
    # 逆方向の循環
    if dest < 0
      dest = STATIONS_YAML.length + dest
    dest

  # チームの現在地を教えてくれる
  robot.hear /now (\w+)/i,(res) ->
    team = JSON.parse(getStrageValue('YLS_TEAMS'))[res.match[1]]
    console.log(team)
    message = "チーム#{res.match[1]}は今#{STATIONS_YAML[team.station].name}にいます"
    res.send(message)

  # 駅のお題を適当に返す
  getTaskRandom = (index)->
    STATIONS_YAML[index].tasks[getRandom(STATIONS_YAML[index].tasks.length)]

  # 駅名からindexを引っ張ってくる。
  # なかったらnull返す
  name2Index = (name) ->
    index = null
    if name
      for i,station of STATIONS_YAML
        if station.name == name
          index = i
          break
    index


  # サイコロをふる。
  robot.hear /roll (\w+)/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    origin = teams[res.match[1]].station
    pips = getRandom(6) + 1
    destination = move(teams[res.match[1]], pips)
    task = getTaskRandom(destination)

    # gotoあったら位置をgotoに合わせる
    gotoIndex = name2Index(task.goto) or destination
    console.log(gotoIndex)
    message = "#{dice}がでました。\n
               #{STATIONS_YAML[origin].name}にいるチーム#{res.match[1]}は
               #{STATIONS_YAML[destination].name}に移動して下さい。\n
               お題は#{task.summary}です。\n
               終わったら#{STATIONS_YAML[gotoIndex].name}でrollしてください"

    res.send(message)
    if gotoIndex != -1
      teams[res.match[1]].station = gotoIndex
    else
      teams[res.match[1]].station = destination

    setStrageValue('YLS_TEAMS',JSON.stringify(teams))

  # 進行を逆向きに(通り過ぎた時用)
  robot.hear /reverse (\w+)/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    console.log(teams)
    teams[res.match[1]].direction *= -1
    if teams[res.match[1]].direction == INNER
      direction = "内回り"
    else
      direction = "外回り"
    setStrageValue('YLS_TEAMS',JSON.stringify(teams))
    res.send("チーム#{res.match[1]}の進行方向を#{direction}に設定しました。")
