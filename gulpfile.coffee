gulp = require 'gulp'
coffee = require 'gulp-coffee'
gulp.task 'compile-coffee', () ->
  gulp.src 'src/**/*.coffee'
    .pipe coffee()
    .pipe gulp.dest('./views/js/')

gulp.task('watch',() ->
  gulp.watch('src/**/*.coffee', ['compile-coffee'])
  )
