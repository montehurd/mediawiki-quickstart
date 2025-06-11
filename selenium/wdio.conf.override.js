'use strict';

require( 'dotenv' ).config();
const { config } = require( '/var/www/html/w/tests/selenium/wdio.conf.js' );

// console.log(JSON.stringify(config, null, 2));

// Docs: https://webdriver.io/docs/configurationfile/

config.specFileRetriesDelay = 5;
config.maxInstances = 1;

if (config.capabilities?.[0]) {
	config.capabilities[0].browserVersion = 'stable'; // Instruct Webdriver v9+ to download Chrome AND its matching chromedriver
	
	if (config.capabilities[0]['goog:chromeOptions']?.args) {
		config.capabilities[0]['goog:chromeOptions'].args.push(
			'--disable-setuid-sandbox', // Disable the setuid sandbox
			'--disable-gpu-sandbox', // Disable the GPU sandbox
			'--disk-cache-dir=/dev/null', // Disable disk cache
			'--disable-background-networking', // Disable background networking
			'--disable-background-timer-throttling', // Disable background timer throttling
			'--disable-backgrounding-occluded-windows', // Disable backgrounding of occluded windows
			'--disable-client-side-phishing-detection', // Disable client-side phishing detection
			'--disable-default-apps', // Disable Chrome's default apps
			'--disable-hang-monitor', // Disable the hang monitor
			'--disable-popup-blocking', // Disable popup blocking
			'--disable-prompt-on-repost', // Disable prompt on repost
			'--disable-sync', // Disable synchronization services
			'--disable-translate', // Disable Chrome translation features
			'--metrics-recording-only', // Only record metrics, don't send them
			'--no-first-run', // Skip the first run tasks
			'--safebrowsing-disable-auto-update', // Disable Safe Browsing auto-update
			'--no-zygote', // Disable the Zygote process
			'--disable-crash-reporter', // Disable crash reporting
			'--disable-metrics', // Disable metrics collection
			'--disable-metrics-reporter', // Disable metrics reporting
			'--disable-software-rasterizer', // Disable software rasterizer
			'--mute-audio', // Mute audio
			'--disable-infobars', // Disable infobars
			'--disable-notifications', // Disable notifications
			'--disable-desktop-notifications' // Disable desktop notifications
		);
	}
}

exports.config = config;

// console.log(JSON.stringify(exports.config, null, 2));