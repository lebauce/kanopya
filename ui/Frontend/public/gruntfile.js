module.exports = function(grunt) {
    // Code Grunt

    // Configuration du projet et des tâches
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        less: {
            compile: {
                options: {
                    // imports: {
                    //     // Use the new "reference" directive, e.g.
                    //     // @import (reference) "variables.less";
                    //     reference: [
                    //         "src/less/variables.less" 
                    //     ]
                    // },
                    compress: true,
                    yuicompress: true,
                    optimization: 2
                },
                files: [
                    {
                      expand: true,
                      cwd: 'src/less', // Source folder
                      // src: ['*.less', '!{var,mix}*.less'],
                      src: 'import.less',
                      dest: 'src/css',
                      ext: '.css'
                    }
                ]
            }
        },

        cssmin: {
            concatenate: {
                files: {
                    'css/styles.css': ['src/css/*.css']
                }
            }
        },

        clean: {
            css: [
                'css/styles.css',
                'src/css/*.css'
            ]
        },

        watch: {
            dev: {
                files: ['src/less/**/*.less'], // which files to watch
                tasks: [
                    'clean:css',
                    'less:compile',
                    'cssmin:concatenate'
                ],
                options: {
                    nospawn: true
                }
            }
        }
    });

    // Chargement des plugins
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-cssmin');
    grunt.loadNpmTasks('grunt-contrib-watch');

    // Définition des tâches Grunt
    // Default : Tâche lancée par défaut (aucune tâche spécifiée)
    grunt.registerTask('default', ['watch:dev']);

    // Active l'option 'force' par défaut
    grunt.option('force', true);

    // Lancer les tâches :
    // grunt
    // grunt dev
    // grunt prod
    // 
    // Force l'exécution de toutes les tâches sans tenir compte des avertissements :
    // grunt dev --force
};
