import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs/promises'
import path from 'path'

export default defineConfig({
  plugins: [
    vue(),
    {
      name: 'serve-results',
      configureServer(server) {
        server.middlewares.use('/api/results', async (req, res) => {
          const resultsDir = process.env.RESULTS_PATH || path.join(process.cwd(), 'public', 'results')
          try {
            if (req.url === '/available') {
              // Dynamically read the directory and format timestamps
              const files = await fs.readdir(resultsDir)
              const results = files
                .filter(f => f.endsWith('.yaml'))
                .map(filename => {
                  // Extract Unix timestamp from filename
                  const timestampStr = filename.replace('.yaml', '')
                  const timestamp = parseInt(timestampStr)
                  const date = new Date(timestamp * 1000)
                  const relatedFiles = files.filter(f => f.startsWith(timestampStr + '.'))
                  return {
                    filename,
                    displayName: date.toUTCString(),
                    files: relatedFiles
                  }
                })
                .sort((a, b) => b.filename.localeCompare(a.filename)) // Sort newest first
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(results))
            } else if (req.url.startsWith('/')) {
              // Serve individual files
              const filename = req.url.substring(1)
              const filepath = path.join(resultsDir, filename)
              const content = await fs.readFile(filepath, 'utf-8')
              let contentType = 'text/plain'
              if (filename.endsWith('.html')) {
                contentType = 'text/html'
              } else if (filename.endsWith('.yaml') || filename.endsWith('.yml')) {
                contentType = 'text/yaml'
              }
              res.setHeader('Content-Type', contentType)
              res.end(content)
            }
          } catch (err) {
            res.statusCode = err.code === 'ENOENT' ? 404 : 500
            res.end(JSON.stringify({ error: err.message }))
          }
        })
      }
    }
  ],
  server: {
    watch: {
      usePolling: true
    },
    allowedHosts: [
      'localhost',
      '127.0.0.1',
      'components-mediawiki-quickstart.wmcloud.org'
    ]
  }
})