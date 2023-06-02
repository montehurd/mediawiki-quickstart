'use strict';

const versionFinder = require( 'puppeteer-chromium-version-finder' );

( async () => {
	const versionObj = await versionFinder.getPuppeteerChromiumVersion();
	const versionStr = `${versionObj.MAJOR}.${versionObj.MINOR}.${versionObj.BUILD}.${versionObj.PATCH}`;
	console.log( versionStr );
} )();
