YamanoteMap = Vue.extend
  template: '
    <circle cx="240" cy="240" r="200"
      fill="none" stroke-width="20" stroke-dasharray="20 10" stroke="black" >
    </circle>
    '
TeamPosition = Vue.extend
  template: '
    <circle
      cx={{posX}}
      cy={{posY}} r="2"
      fill="red" stroke-width="10" stroke="red">
    </circle>
    '
  props: ['station']
  computed:
    posX: ->
      (240+200*Math.cos(12*this.station/180*Math.PI)).toString
    posY: ->
      (240+200*Math.sin(12*this.station/180*Math.PI)).toString

vm = new Vue(
  el: "#app"
  components: {
    'yamanaote-map': YamanoteMap
    'team-position': TeamPosition
  }
)
