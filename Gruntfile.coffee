
module.exports = (grunt)->  

  grunt.initConfig

    pkg: grunt.file.readJSON 'package.json'

    jade:
      dev:
        options:
          pretty: yes
        files:
          'temp/_template.html': 'src/abn_tree_template.jade'
          'test/tests_page.html': 'test/tests_page.jade'
          
      #
      # Generate 4 test pages, for all combinations of:
      # 
      # Bootstrap 2 and 3
      # Angular 1.1.5 and 1.2.0
      # 
    
      bs2_ng115_test_page:
        files:
          'test/bs2_ng115_test_page.html': 'test/test_page.jade'
        options:
          pretty: yes
          data:
            bs: "2"
            ng: "1.1.5"

      bs3_ng115_test_page:
        files:
          'test/bs3_ng115_test_page.html': 'test/test_page.jade'
        options:
          pretty: yes
          data:
            bs: "3"
            ng: "1.1.5"

      bs2_ng120_test_page:
        files:
          'test/bs2_ng120_test_page.html': 'test/test_page.jade'
        options:
          pretty: yes
          data:
            bs: "2"
            ng: "1.2.12"

      bs3_ng120_test_page:
        files:
          'test/bs3_ng120_test_page.html': 'test/test_page.jade'
        options:
          pretty: yes
          data:
            bs: "3"
            ng: "1.2.12"

      bs3_ng130_test_page:
        files:
          'test/bs3_ng130_test_page.html': 'test/test_page.jade'
        options:
          pretty: yes
          data:
            bs: "3"
            ng: "1.3.0"


    "string-replace":
      dev:
        files:
          #
          # substitute the "template html" into an intermediate coffeescript file
          # ( to take advantage of triple-quoted strings )
          #
          'temp/_directive.coffee': 'src/abn_tree_directive.coffee'
        options:
          replacements: [
            pattern: "{html}"
            replacement_old: "<h1>i am the replacement!</h1>"
            replacement: ->
              grunt.file.read('temp/_template.html')
          ]

    coffee:
      dev:
        options:
          bare: no
        files:
          #
          # the _temp.coffee file has the "template html" baked-in by Grunt
          #
          'dist/abn_tree_directive.js': 'temp/_directive.coffee'
          'test/test_page.js': 'test/test_page.coffee'

    less:
      dev:
        files:
          'dist/abn_tree.css': 'src/abn_tree.less'

    connect:
      dev:
        options:
          port: 1337
          livereload: yes
          open:
            target: 'http://127.0.0.1:<%= connect.dev.options.port %>/test/bs3_ng130_test_page.html'

    watch:
      dev:
        files: ['**/*.jade', '**/*.less', '**/*.coffee']
        tasks: ['build']
        options:
          livereload: yes

  require('load-grunt-tasks')(grunt)

  grunt.registerTask 'build', ['jade', 'less', 'string-replace', 'coffee']
  grunt.registerTask 'default', ['build', 'connect:dev', 'watch']



