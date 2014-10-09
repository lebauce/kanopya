module.exports = function(grunt) {
    // Code Grunt

    // Configuration du projet et des tâches
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            development: {
                options: {
                    compress: true,
                    yuicompress: true,
                    optimization: 2
                },
                files: {
                    // target.css file: source.less file
                    "css/dialog.css": "less/dialog.less"
                }
            }
        },
        watch: {
            less: {
                files: ['less/*.less'], // which files to watch
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
