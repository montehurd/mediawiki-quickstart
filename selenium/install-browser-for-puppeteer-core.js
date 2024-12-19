/* eslint-disable n/no-process-exit */
'use strict';

const { execSync } = require( 'child_process' );

function getPuppeteerCoreVersion() {
	// return "21.5.6"
	const output = execSync( 'npm list puppeteer-core' ).toString();
	const match = output.match( /puppeteer-core@([\d.]+)/ );
	return match ? match[ 1 ] : null;
}

function getChromeToChromiumMap() {
	return {
		'73.0.3679.0': '624492',
		'74.0.3723.0': '637110',
		'75.0.3765.0': '650583',
		'76.0.3803.0': '662092',
		'77.0.3803.0': '674921',
		'78.0.3882.0': '686378',
		'79.0.3942.0': '706915',
		'80.0.3987.0': '722234',
		'81.0.4044.0': '737027',
		'83.0.4103.0': '756035',
		'84.0.4147.0': '768783',
		'85.0.4182.0': '782078',
		'86.0.4240.0': '800071',
		'87.0.4272.0': '809590',
		'88.0.4298.0': '818858',
		'89.0.4389.0': '843427',
		'90.0.4403.0': '848005',
		'90.0.4427.0': '856583',
		'91.0.4469.0': '869685',
		'92.0.4512.0': '884014',
		'93.0.4577.0': '901912',
		'97.0.4692.0': '938248',
		'98.0.4758.0': '950341',
		'99.0.4844.16': '961656',
		'100.0.4889.0': '970485',
		'101.0.4950.0': '982053',
		'102.0.5002.0': '991974',
		'103.0.5059.0': '1002410',
		'104.0.5109.0': '1011831',
		'105.0.5173.0': '1022525',
		'106.0.5249.0': '1036745',
		'107.0.5296.0': '1045629',
		'108.0.5351.0': '1056772',
		'109.0.5412.0': '1069273',
		'110.0.5479.0': '1083080',
		'111.0.5556.0': '1095492',
		'112.0.5614.0': '1108766'
	};
}

function getBrowserVersions() {
	const versionsJson = JSON.parse( execSync( 'curl -s https://raw.githubusercontent.com/puppeteer/puppeteer/main/versions.json' ).toString() );
	return versionsJson.versions;
}

// Pre v20 "@puppeteer/browsers install" needs the "chromium" revision for the "chrome" version
function resolveBrowserVersions( versions ) {
	const chromeToChromiumMap = getChromeToChromiumMap();
	return versions.map( ( [ version, data ] ) => {
		const chromiumRevision = chromeToChromiumMap[ data.chrome ];
		if ( chromiumRevision ) {
			return [ version, { chromium: chromiumRevision } ];
		}
		return [ version, { chrome: data.chrome } ];
	} );
}

function parseVersion( versionString ) {
	const parts = versionString.replace( /^v/, '' ).split( '.' ).map( Number );
	return { major: parts[ 0 ], minor: parts[ 1 ], patch: parts[ 2 ] || 0 };
}

function isVersionLessOrEqual( v1, v2 ) {
	return v1.major < v2.major ||
         ( v1.major === v2.major && v1.minor < v2.minor ) ||
         ( v1.major === v2.major && v1.minor === v2.minor && v1.patch <= v2.patch );
}

function getClosestVersion( puppeteerVersion, versions ) {
	const targetVersion = parseVersion( puppeteerVersion );
	for ( const [ version, data ] of versions ) {
		const currentVersion = parseVersion( version );
		if ( isVersionLessOrEqual( currentVersion, targetVersion ) ) {
			return data.chromium ?
				{ name: 'chromium', version: data.chromium } :
				{ name: 'chrome', version: data.chrome };
		}
	}
	return null;
}

function main() {
	const puppeteerVersion = getPuppeteerCoreVersion();
	if ( !puppeteerVersion ) {
		console.error( 'Error: Could not determine puppeteer-core version' );
		process.exit( 1 );
	}

	const rawVersions = getBrowserVersions();
	const resolvedVersions = resolveBrowserVersions( rawVersions );

	// console.log(resolvedVersions)
	// process.exit(1)

	const browserInfo = getClosestVersion( puppeteerVersion, resolvedVersions );
	if ( !browserInfo ) {
		console.error( `Error: Could not determine browser version for Puppeteer ${ puppeteerVersion }` );
		process.exit( 1 );
	}

	const installCommand = `npx @puppeteer/browsers install ${ browserInfo.name }@${ browserInfo.version }`;

	try {
		const output = execSync( installCommand, { stdio: 'pipe', cwd: './vendor/' } ).toString();
		const match = output.match( /\/.*$/m );
		const installedPath = match ? match[ 0 ] : undefined;
		if ( !installedPath ) {
			throw new Error( 'Could not determine installed path' );
		}
		console.log( installedPath );
		process.exit( 0 );
	} catch ( error ) {
		console.error( error.message );
		process.exit( 1 );
	}
}

main();
