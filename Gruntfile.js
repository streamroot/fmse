module.exports = function(grunt) {
  require("matchdep").filterDev("grunt-*").forEach(grunt.loadNpmTasks);

  grunt.registerTask('default', ['browserify:main']);
  grunt.registerTask('debug', ['browserify:debug']);


  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    browserify: {
      main: {
        src: 'src/js/Main.js',
        dest: 'build/fMSE.js',
        options:  {
          transform: ['babelify'],
          browserifyOptions: {
            standalone: 'fMSE.init',
            debug: true
          },
          watch: true,
          keepAlive: true
        }
      },
      debug: {
        src: 'debug/BufferDisplay.js',
        dest: 'debug/build/BufferDisplay.js',
        options:  {
          transform: ['babelify'],
          browserifyOptions: {
            standalone: 'fMSE.debug.bufferDisplay',
            debug: true
          },
          watch: true,
          keepAlive: true
        }
      },
    }
  });
};
