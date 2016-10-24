# YamanoteLineSugoroku Organizer
# Commands:
# now [チーム名]
# roll [チーム名]
# reverse [チーム名]
# team list
# team add [チーム名] [初期駅名] [外or内]

module.exports = (robot) ->
  yaml =require('js-yaml')
  fs = require('fs')
  request = require('request')
  tasksFilePath = './public/tasks.yaml'
  STATIONS_YAML = yaml.load(fs.readFileSync( tasksFilePath, 'utf8'))

  INNER = 1
  OUTER = -1
  TEAMS_INITIALIZER =
    'red':
      direction:INNER
      station: 0
      doingTask: false
    'blue':
      direction:OUTER
      station:0
      doingTask: false

  getStrageValue = (key) ->
    robot.brain.get(key)

  setStrageValue = (key,value) ->
    robot.brain.set(key,value)

  LoadStationTask = (YamlUrl) ->
    if YamlUrl?
      tasksFilePath = YamlUrl
      robot.logger.info "Station file source: #{tasksFilePath}"
      request tasksFilePath ,(err,res) ->
        if err?
          robot.logger.error "Station file load Failed...:#{err}"
        else
          STATIONS_YAML = yaml.load(res.body)
          console.log STATIONS_YAML.length
          robot.logger.info "Station file load OK."
    else
      tasksFilePath = './public/tasks.yaml'
      robot.logger.info "Station file source: #{tasksFilePath}"
      STATIONS_YAML = yaml.load(fs.readFileSync( tasksFilePath, 'utf8'))


  writeLog = (message) ->
    logs = JSON.parse(getStrageValue('YLS_LOGS'))
    if logs == null then logs = []
    console.log('write:',message)
    logs.push(message)
    if logs.length > 10 then logs.shift()
    setStrageValue('YLS_LOGS',JSON.stringify(logs))
    console.log('logs:',logs)

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

  robot.enter (res) ->
    setStrageValue('YLS_TEAMS',JSON.stringify(TEAMS_INITIALIZER))
    res.send("HI")

  robot.hear /init ([0-9]+)/i,(res) ->
    STATIONS_YAML = LoadStationTask(process.env.HUBOT_YLSBOT_TASK_FILE_PATH)

    setStrageValue('YLS_TEAMS',JSON.stringify(TEAMS_INITIALIZER))
    res.send("initialized!")

  # チーム一覧
  robot.hear /(team *list)|チーム一覧/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    message = ""
    for team in Object.keys(teams)
      message += "・#{team}:#{STATIONS_YAML[teams[team].station].name}\n"
    res.send(message)

  # チーム追加
  robot.hear /team +add *(.+) (.+) (内|外)/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    teamName = res.match[1]
    station = name2Index(res.match[2])
    doingTask = false
    if station == null
      res.send("そんな駅ないよ\n" +
      "team add [チーム名] [初期駅名] [外or内]")
      return

    if res.match[3] == '内'
      direction = INNER
    else
      direction = OUTER

    teams[teamName] =
      direction: direction
      station: station
    console.log(teams)
    setStrageValue('YLS_TEAMS',JSON.stringify(teams))
    res.send("チーム「#{teamName}」を\n#{res.match[2]}スタート" +
      "#{res.match[3]}周りで追加しました。")

  # チームの現在地を教えてくれる
  robot.hear /(now *(\S+))|((\S+).*どこ)/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    if !teams[res.match[2]]
      console.log("now:#{res.match[2]}")
      return
    team = teams[res.match[2]]
    console.log(team)
    message = "チーム#{res.match[2]}は今" +
      "#{STATIONS_YAML[team.station].name}にいます"
    res.send(message)

  # サイコロをふる。
  robot.hear /(roll|🎲) *(\S+)/i,(res) ->
    name = res.match[2]
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    console.log("roll: ")
    if !teams[name]
      res.send("そんなちーむいないよ")
      return
    if teams[name].doingTask
      message = "チーム#{name}はまだお題をこなしていません。\n" +
        "お題が終わったら`done #{name}`と発言してください。"
      res.send(message)
      return

    origin = teams[name].station
    pips = getRandom(6) + 1
    destination = move(teams[name], pips)
    task = getTaskRandom(destination)

    # gotoあったら位置をgotoに合わせる
    gotoIndex = name2Index(task.goto) or destination
    teams[name].station = gotoIndex
    teams[name].doingTask = true
    setStrageValue('YLS_TEAMS',JSON.stringify(teams))

    message = "#{pips}がでました。\n" +
      "#{STATIONS_YAML[origin].name}にいるチーム#{name}は" +
      "#{STATIONS_YAML[destination].name}に移動して下さい。\n" +
      "お題は「#{task.summary}」です。\n" +
      "終わったら`done #{name}`と発言してください。"
    writeLog(message)
    res.send(message)

  # 課題が終わったのでサイコロ振る権利を得る
  robot.hear /(done|✔️|✅|🏁) *(\S+)/i,(res) ->
    name = res.match[2]
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    team = teams[name]
    console.log("done #{name}")
    if !team
      res.send("そんなちーむいないよ")
      return
    team.doingTask = false
    setStrageValue('YLS_TEAMS',JSON.stringify(teams))
    message = "お疲れ様でした。"+
      "チーム #{name}は#{STATIONS_YAML[team.station].name}で次のサイコロを振って下さい。"
    res.send(message)

  # 進行を逆向きに(通り過ぎた時用)
  robot.hear /(🔙|reverse) *(\S+)/i,(res) ->
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    console.log(teams)
    name = res.match[2]
    if !teams[name]
      res.send("そんなちーむいないよ")
      return
    teams[name].direction *= -1
    if teams[name].direction == INNER
      direction = "内回り"
    else
      direction = "外回り"
    setStrageValue('YLS_TEAMS',JSON.stringify(teams))
    message = "チーム#{name}の進行方向を#{direction}に設定しました。"
    res.send(message)
    writeLog(message)

  #指定した駅のタスク一覧を出す(確認用)
  robot.hear /🚉 *(\S+)/i,(res)->
    unless name2Index(res.match[1])? then return
    summaries = STATIONS_YAML[name2Index(res.match[1])].tasks
    res.send (summaries.map (t)-> "・#{t.summary}").join("\r\n")


  robot.router.set('view engine', 'pug')
  robot.router.get '/', (req, res) ->
    console.log("get root")
    teams = JSON.parse(getStrageValue('YLS_TEAMS'))
    logs = JSON.parse(getStrageValue('YLS_LOGS'))
    console.log(logs)
    res.render('index',{teams: teams,logs: logs})
