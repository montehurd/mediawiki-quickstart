'use strict';

require( 'dotenv' ).config();
const { config } = require( './wdio.conf.js' );

// docs: https://webdriver.io/docs/configurationfile/
exports.config = { ...config,
	specFileRetriesDelay: 5,
	maxInstances: 1,
	capabilities: [ {
		browserName: 'chrome',
		'goog:chromeOptions': {
			args: [
				'--enable-automation',
	      '--no-sandbox',                         // Disable the sandbox for all processes
	      '--disable-setuid-sandbox',             // Disable the setuid sandbox
	      '--disable-dev-shm-usage',              // Use /tmp instead of /dev/shm
	      '--disable-gpu',                        // Disable GPU hardware acceleration
	      '--disable-gpu-sandbox',                // Disable the GPU sandbox
	      '--disk-cache-dir=/dev/null',           // Disable disk cache
	      '--disable-background-networking',      // Disable background networking
	      '--disable-background-timer-throttling',// Disable background timer throttling
	      '--disable-backgrounding-occluded-windows', // Disable backgrounding of occluded windows
	      '--disable-client-side-phishing-detection', // Disable client-side phishing detection
	      '--disable-default-apps',               // Disable Chrome's default apps
	      '--disable-hang-monitor',               // Disable the hang monitor
	      '--disable-popup-blocking',             // Disable popup blocking
	      '--disable-prompt-on-repost',           // Disable prompt on repost
	      '--disable-sync',                       // Disable synchronization services
	      '--disable-translate',                  // Disable Chrome translation features
	      '--metrics-recording-only',             // Only record metrics, don't send them
	      '--no-first-run',                       // Skip the first run tasks
	      '--safebrowsing-disable-auto-update',   // Disable Safe Browsing auto-update
	      '--no-zygote',                          // Disable the Zygote process
	      '--disable-crash-reporter',             // Disable crash reporting
	      '--disable-metrics',                    // Disable metrics collection
	      '--disable-metrics-reporter',           // Disable metrics reporting
	      '--disable-software-rasterizer',        // Disable software rasterizer
	      '--mute-audio',                         // Mute audio
	      '--disable-infobars',                   // Disable infobars
	      '--disable-notifications',              // Disable notifications
	      '--disable-desktop-notifications'       // Disable desktop notifications
			]
		}
	} ],
};
