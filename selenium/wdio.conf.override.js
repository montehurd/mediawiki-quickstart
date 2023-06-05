'use strict';

require( 'dotenv' ).config();
const { config } = require( './wdio.conf.js' );

const chromiumEndpoint = 'ws://docker-chromium-novnc-chromium-1:3111/ws';

// docs: https://webdriver.io/docs/configurationfile/
exports.config = { ...config,

	before: function () {
		browser.setWindowSize( 1280, 1024 );
	},

	/*
	before: function ( capabilities, specs ) {
		browser.setWindowSize( 1280, 1024 );
	},
	before: async function () {
	   const [ width, height ] = await browser.execute( () => {
	       return [ window.innerWidth, window.innerHeight ];
	   } );
     console.log( `${width} ${height}` );
	   await browser.setWindowSize( width, height );
	},
	*/

	specFileRetriesDelay: 5,
	maxInstances: 1,
	capabilities: [ {
		browserName: 'chromium',
		'wdio:devtoolsOptions': {
			slowMo: 25,
			headless: false,
			ignoreHTTPSErrors: true,
			browserWSEndpoint: chromiumEndpoint,
		}
	} ],
};
