module.exports = function(grunt) {
  require("matchdep").filterDev("grunt-*").forEach(grunt.loadNpmTasks);

  grunt.registerTask('default', ['browserify']);

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    browserify: {
      main: {
        src: 'src/js/main.js',
        dest: 'build/fMSE.js',
        options:  {
          transform: ['babelify'],
          browserifyOptions: {
            debug: true
          },
          watch: true,
          keepAlive: true
        }
      }
    }
  });
};
