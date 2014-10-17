module.exports = function(grunt) {
    // Code Grunt

    // Configuration du projet et des tâches
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            components: {
                options: {
                    // imports: {
                    //     // Use the new "reference" directive, e.g.
                    //     // @import (reference) "variables.less";
                    //     reference: [
                    //         "less/variables.less" 
                    //     ]
                    // },
                    compress: true,
                    yuicompress: true,
                    optimization: 2
                },
                files: [
                    {
                      expand: true,
                      cwd: 'less',
                      src: ['*.less', '!{var,mix}*.less'],
                      dest: 'css/',
                      ext: '.css'
                    }
                ]
            }
        },
        watch: {
            less: {
                files: ['less/**/*.less'], // which files to watch
                tasks: ['less'],
                options: {
                    nospawn: true
                }
            }
        }
    });

    // Chargement des plugins
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');

    // Définition des tâches Grunt
    // Default : Tâche lancée par défaut (aucune tâche spécifiée)
    grunt.registerTask('default', ['watch']);

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
