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

  const extraArgs = args.slice(firstFlagIndex)

  if (extraArgs.includes('--spec')) {
    const specIndex = extraArgs.indexOf('--spec')
    if (specIndex + 1 < extraArgs.length) {
      extraArgs[specIndex + 1] = process.cwd() + '/' + extraArgs[specIndex + 1]
    }
  }

  console.error('Injecting wdio args:', extraArgs)
  process.argv.push(...extraArgs)
}