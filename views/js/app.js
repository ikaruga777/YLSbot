(function() {
  var vm;

  vm = new Vue({
    el: ".app",
    data: {
      teams: {}
    },
    created: function() {
      var teams;
      return teams = {
        red: "www",
        blue: "eee"
      };
    }
  });

}).call(this);
