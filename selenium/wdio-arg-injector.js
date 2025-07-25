// Inject WDIO_INJECTION_ARGS into the wdio process's args

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
// script before wdio starts, which then injects our arguments directly
// into wdio's process.argv regardless of how deeply nested or how the
// npm script is structured
//
// The WDIO_INJECTION_ARGS env var also provides a clean way to pass
// arguments from the host across the container boundary without having
// to worry about shell escaping complexities.

if (process.env.WDIO_INJECTION_ARGS) {
  const isWdio = process.argv[1] && (
    process.argv[1].endsWith('/wdio') ||
    process.argv[1].includes('@wdio/cli')
  )
  // console.log(`Injection candidate process: ${process.argv[1]}`)
  if (!isWdio) {
    return
  }
  // Decode and split on null bytes
  const decoded = Buffer.from(process.env.WDIO_INJECTION_ARGS, 'base64').toString().trim()
  if (decoded === '\0' || decoded == '') {
    return
  }
  const args = decoded.split('\0').filter(arg => arg)
  // console.error('Decoded args:', args)
  const firstFlagIndex = args.findIndex(arg => arg.startsWith('--'))
  if (firstFlagIndex === -1) {
    return
  }

  let extraArgs = args.slice(firstFlagIndex)

  const waitIndex = extraArgs.indexOf('--wait-for-debugger');
  if (waitIndex !== -1) {
    process.env.NODE_OPTIONS = (process.env.NODE_OPTIONS || '') + ' --inspect-brk=0.0.0.0:9229'
    extraArgs.splice(waitIndex, 1)
    const maxIndex = extraArgs.indexOf('--maxInstances')
    if (maxIndex !== -1) extraArgs.splice(maxIndex, 2)
    extraArgs.push('--maxInstances', '1')
  }

  if (extraArgs.includes('--spec')) {
    const specIndex = extraArgs.indexOf('--spec')
    if (specIndex + 1 < extraArgs.length) {
      const specPath = extraArgs[specIndex + 1]
      if (!specPath.startsWith('/')) {
        extraArgs[specIndex + 1] = process.cwd() + '/' + specPath
      }
    }
  }

  console.error('Injecting wdio args:', extraArgs)

  if (waitIndex !== -1) {
    setTimeout(() => console.error('\x1b[33m\n\nWaiting for debugger attachment ("--wait-for-debugger" detected)...\n\n- 1: Open the mediawiki-quickstart folder in VSCode\n- 2: Set needed breakpoints in your Selenium files\n- 3: In the VSCode debugger section select \x1b[32m\u25B6\uFE0F Attach to Selenium WDIO Worker\x1b[0m\n\n\x1b[0m'), 5000)
  }

  process.argv.push(...extraArgs)
}


// maxInstances should be moved into capabilities entry upstream - can it accept env var override?
// edit the file directly next to test, then open a PR if works


// (async () => {
//   const module = await import('/var/www/html/w/tests/selenium/wdio.conf.js')
//   const config = module.config
//   console.log('Effective WDIO Config:', JSON.stringify(config, null, 2))
// })()