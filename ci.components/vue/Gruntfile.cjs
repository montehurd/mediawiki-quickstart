module.exports = function ( grunt ) {
	const conf = grunt.file.exists( 'extension.json' ) ?
		grunt.file.readJSON( 'extension.json' ) :
		{ MessagesDirs: {} };

	grunt.loadNpmTasks( 'grunt-banana-checker' );
	grunt.loadNpmTasks( 'grunt-eslint' );
	grunt.loadNpmTasks( 'grunt-stylelint' );

	grunt.initConfig( {
		eslint: {
			options: {
				extensions: [ '.js', '.json', '.vue' ],
				cache: true,
				fix: grunt.option( 'fix' )
			},
			all: [
				'**/*.{js,json,vue}',
				'!{node_modules,public}/**',
				'!dist/**',
				'!ci.components/runs/**',
                '!package.json',
                '!package-lock.json',
			]
		},
		stylelint: {
			options: { cache: true },
			all: [
				'**/*.{less,vue}',
				'!node_modules/**',
				'!vendor/**',
				'!lib/**',
				'!dist/**',
                '!package.json',
                '!package-lock.json',
			]
		},
		banana: conf.MessagesDirs
	} );

	grunt.registerTask( 'test', [ 'eslint', 'stylelint', 'banana' ] );
	grunt.registerTask( 'default', 'test' );
	grunt.registerTask( 'fix', () => {
		grunt.config.set( 'eslint.options.fix', true );
		grunt.task.run( 'eslint' );
	} );
};
