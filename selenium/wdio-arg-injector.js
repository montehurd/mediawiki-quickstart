// Inject arguments into wdio or Cypress processes
//
// We might later want to rename this script something like
// testing-arg-injector.js - and WDIO_INJECTION_ARGS too.
// 
// Injection is needed because we can't rely on npm's built-in argument
// forwarding (npm run selenium-test -- args). This is because many
// package.json selenium-test scripts don't pass through arguments -
// they might use && chains, wrapper scripts, or hardcoded wdio calls
//
// Even worse, some scripts call other npm run scripts
//   (e.g., "selenium-test": "npm run test:selenium")
// which breaks npm's -- forwarding entirely
//
// Since we don't control these package.json files in MediaWiki
// core/extensions/skins, we use NODE_OPTIONS to require this injector
// script before the test runner starts, which then injects our arguments
// directly into process.argv regardless of how deeply nested or how the
// npm script is structured
//
// The WDIO_INJECTION_ARGS env var also provides a clean way to pass
// arguments from the host across the container boundary without having
// to worry about shell escaping complexities.

'use strict';

const isWdio = process.argv[1] && (
  process.argv[1].endsWith('/wdio') ||
  process.argv[1].includes('@wdio/cli')
);

const isCypress = process.argv[1] && (
  process.argv[1].endsWith('/cypress')
);

// console.log(`Injection candidate process: ${process.argv[1]}`)
if (!isWdio && !isCypress) {
  return;
}

// Cypress: use shared cache location, inject --headed when DISPLAY is set
const isCypressOpen = isCypress && process.argv.includes('open');
const isCypressRun = isCypress && process.argv.includes('run');
if (isCypress) {
  delete process.env.CYPRESS_CACHE_FOLDER;
  if (isCypressRun && process.env.DISPLAY && !process.argv.includes('--headed')) {
    console.error('Injecting Cypress arg: --headed (DISPLAY is set)');
    process.argv.push('--headed');
  }
}

if (!process.env.WDIO_INJECTION_ARGS) {
  return;
}

// Decode and split on null bytes
const decoded = Buffer.from(process.env.WDIO_INJECTION_ARGS, 'base64').toString().trim();
if (decoded === '\0' || decoded === '') {
  return;
}

const args = decoded.split('\0').filter(arg => arg);
// console.error('Decoded args:', args)
const firstFlagIndex = args.findIndex(arg => arg.startsWith('--'));
if (firstFlagIndex === -1) {
  return;
}

let extraArgs = args.slice(firstFlagIndex);

// Handle --wait-for-debugger (wdio only - doesn't work with Cypress/Electron)
if (isWdio) {
  const waitIndex = extraArgs.indexOf('--wait-for-debugger');
  if (waitIndex !== -1) {
    process.env.NODE_OPTIONS = (process.env.NODE_OPTIONS || '') + ' --inspect-brk=0.0.0.0:9229';
    extraArgs.splice(waitIndex, 1);

    const maxIndex = extraArgs.indexOf('--maxInstances');
    if (maxIndex !== -1) extraArgs.splice(maxIndex, 2);
    extraArgs.push('--maxInstances', '1');

    setTimeout(() => console.error(`
\x1b[32mWaiting for debugger attachment ("--wait-for-debugger" flag detected)...\x1b[0m
\x1b[33m
- 1: In VSCode, open the 'mediawiki-quickstart' folder
- 2: In VSCode, find your Selenium test file within 'mediawiki-quickstart/mediawiki' and set needed breakpoint(s)
- 3: Use Ctrl+Shift+D (Shift+Command+D on MacOS) to show VSCode debug panel
- 4: Click \x1b[32m\u25B6\uFE0F\x1b[0m Attach to Selenium WDIO Worker \x1b[33mnear the top of the VSCode debug panel to continue execution with debugging\x1b[0m
    `), 5000);
  }
}

// Handle --spec (convert relative to absolute path) - not supported by cypress open
const specIndex = extraArgs.indexOf('--spec');
if (specIndex !== -1) {
  if (isCypressOpen) {
    // Remove --spec and its value for cypress open (not supported)
    extraArgs.splice(specIndex, 2);
  } else if (specIndex + 1 < extraArgs.length) {
    const specPath = extraArgs[specIndex + 1];
    if (!specPath.startsWith('/')) {
      extraArgs[specIndex + 1] = process.cwd() + '/' + specPath;
    }
  }
}

const runner = isWdio ? 'wdio' : 'Cypress';
console.error(`Injecting ${runner} args:`, extraArgs);

process.argv.push(...extraArgs);

// (async () => {
//   const module = await import('/var/www/html/w/tests/selenium/wdio.conf.js')
//   const config = module.config
//   console.log('Effective WDIO Config:', JSON.stringify(config, null, 2))
// })()
