// Load gulp and other required modules
var gulp = require('gulp'),
    jshint = require('gulp-jshint'),
    exec = require('gulp-exec'),
    gutil = require('gulp-util');

// Lint javascript cloud code
gulp.task('lint', function () {
  gulp.src(['./cloud/main.js'])
    .pipe(jshint('.jshintrc'))
    .pipe(jshint.reporter('jshint-stylish'));
});

gulp.task('watch', function () {
  gulp.watch('./cloud/main.js', ['lint']);
});

function onLintError(error) {
  gutil.log('Error: cloud code must be linted before deployment.');
  process.exit(1);
}

gulp.task('deploy', function () {
  var options = {
    continueOnError: false,
    pipeStdout: false,
    customTemplatingThing: 'test'
  };
  var reportOptions = {
    err: true,
    stderr: true,
    stdout: true
  };

  gulp.src(['./cloud/main.js'])
    .pipe(jshint('.jshintrc'))
    .pipe(jshint.reporter('jshint-stylish'))
    .pipe(jshint.reporter('fail'))
    .on('error', onLintError);

  gulp.src('./')
    .pipe(exec('parse deploy', options))
    .pipe(exec.reporter(reportOptions));
});

gulp.task('default', ['watch']);
