path = require "path"
gulp = require "gulp"
$ = do require "gulp-load-plugins"
del = require "del"
webpack = require "webpack"
server = require("browser-sync").create()
runSequence = require "run-sequence"
minimist = require "minimist"
spawn = require("child_process").spawn


gulp.task "server", (cb) ->
  server.init
    notify: false
    server: {
      baseDir: "dist"
    }
  cb()


gulp.task "server:reload", (cb) ->
  server.reload()
  cb()


gulp.task "clean", (cb) ->
  del [
    "dist"
  ], cb


gulp.task "copy", ->
  gulp.src ["assets/**/*"], base: "assets"
  .pipe gulp.dest "dist"
  .pipe server.stream()


gulp.task "jade", ->
  delete require.cache[__dirname + "/config.coffee"]
  config = require "./config.coffee"
  
  # pages
  config.blocks.forEach (block) ->
    block.items.forEach (item) ->
      gulp.src "src/jade/single.jade"
      .pipe $.plumber()
      .pipe $.data ->
        title: config.title
        item: item
      .pipe $.jade pretty: true
      .pipe $.rename "#{item.id}.html"
      .pipe gulp.dest "dist"

  # index
  gulp.src "src/jade/index.jade"
  .pipe $.plumber()
  .pipe $.data -> config
  .pipe $.jade pretty: true
  .pipe gulp.dest "dist"
  .pipe server.stream()


gulp.task "webpack", (cb) ->
  webpack
    entry:
      app: "./src/coffee/app.coffee"
    output:
      path: path.join(__dirname, "dist/js")
      filename: "[name].bundle.js"
    devtool: "#source-map"
    resolve:
      extensions: ["", ".js", ".coffee", ".webpack.js", ".web.js"]
    module:
      loaders: [
        {test: /\.coffee$/, loader: "coffee-loader"}
      ]
  
  , (err, stats) ->
    if err
      throw new $.util.PluginError "webpack", err

    $.util.log "[webpack]", stats.toString()

    server.reload()
    cb()


gulp.task "uglify", ->
  gulp.src "dist/js/**/*.js"
  .pipe $.plumber()
  .pipe $.uglify preserveComments: "some"
  .pipe gulp.dest "dist/js"
  .pipe server.stream()


gulp.task "sass", ->
  gulp.src "src/sass/**/*.scss"
  .pipe $.plumber()
  .pipe $.sass.sync(outputStyle: "compressed").on "error", $.sass.logError
  .pipe $.autoprefixer
    browsers: [
      "last 4 versions"
      "ie 9"
      "iOS 6"
      "Android 4"
    ]
  .pipe gulp.dest "dist/css"
  .pipe server.stream()


gulp.task "build", (cb) ->
  runSequence(
    "clean",
    "copy",
    ["webpack", "sass", "jade"],
    "uglify",
    cb
  )


gulp.task "watch", (cb) ->
  $.watch "assets/**/*", ->
    gulp.start "copy"
  
  $.watch [
    "src/jade/**/*"
    "config.coffee"
  ], ->
    gulp.start "jade"
  
  $.watch "src/coffee/**/*", ->
    gulp.start "webpack"
  
  $.watch "src/sass/**/*", ->
    gulp.start "sass"


gulp.task "start", (cb) ->
  runSequence(
    "build",
    ["server", "watch"],
    cb
  )


gulp.task "default", ["start"]