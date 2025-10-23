import {defineConfig} from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs/promises'
import path from 'path'
import fss from 'fs'

const getHeadersForFile = (filename) => {
    const ext = path.extname(filename).toLowerCase()
    const extensionHeaders = {
        '.html': {'Content-Type': 'text/html'},
        '.yaml': {'Content-Type': 'text/yaml'},
        '.yml': {'Content-Type': 'text/yaml'},
        '.ansi': {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': `attachment; filename="${filename}"`
        }
    }
    return extensionHeaders[ext] || {'Content-Type': 'text/plain'}
}

export default defineConfig({
    plugins: [
        vue(),
        {
            name: 'serve-results',
            configureServer(server) {
                const resultsDir = process.env.RESULTS_PATH || path.join(process.cwd(), 'ci.components', 'runs')
                const base = path.normalize(resultsDir + path.sep)

                const exists = async (p) => {
                    try {
                        await fs.access(p);
                        return true
                    } catch {
                        return false
                    }
                }

                server.middlewares.use('/api/results', async (req, res) => {
                    try {
                        if (req.url === '/available') {
                            const dirents = await fs.readdir(resultsDir, {withFileTypes: true})
                            const runs = dirents
                                .filter(d => d.isDirectory() && /^\d+$/.test(d.name))
                                .map(d => d.name)
                                .sort((a, b) => b.localeCompare(a))

                            const results = []
                            for (const ts of runs) {
                                const yamlRel = `${ts}/${ts}.yaml`
                                const ansiRel = `${ts}/${ts}.logs.ansi`
                                const htmlRel = `${ts}/${ts}.logs.ansi.html`

                                // parallel file checks
                                const [ansiOk, htmlOk] = await Promise.all([
                                    exists(path.join(resultsDir, ansiRel)),
                                    exists(path.join(resultsDir, htmlRel)),
                                ])

                                const files = []
                                if (ansiOk) files.push(ansiRel)
                                if (htmlOk) files.push(htmlRel)

                                results.push({
                                    filename: yamlRel,
                                    timestamp: ts,
                                    displayName: new Date(parseInt(ts, 10) * 1000).toUTCString(),
                                    files
                                })
                            }

                            res.setHeader('Content-Type', 'application/json')
                            res.setHeader('Cache-Control', 'public, max-age=15, stale-while-revalidate=60')
                            return res.end(JSON.stringify(results))
                        }

                        if (req.url && req.url.startsWith('/')) {
                            const rel = req.url.slice(1).split('?')[0]
                            const candidate = path.join(resultsDir, rel)

                            if (!candidate.startsWith(base)) {
                                res.statusCode = 403
                                res.setHeader('Content-Type', 'application/json')
                                return res.end('{"error":"Forbidden"}')
                            }

                            const headers = getHeadersForFile(rel)
                            for (const [k, v] of Object.entries(headers)) res.setHeader(k, v)
                            res.setHeader('Cache-Control', 'public, max-age=300, stale-while-revalidate=86400')

                            const stream = fss.createReadStream(candidate)
                            stream.on('error', (err) => {
                                res.statusCode = err.code === 'ENOENT' ? 404 : 500
                                res.setHeader('Content-Type', 'application/json')
                                res.end('{"error":"' + err.message.replace(/"/g, '\\"') + '"}')
                            })
                            stream.pipe(res)
                            return
                        }

                        res.statusCode = 404
                        res.setHeader('Content-Type', 'application/json')
                        res.end(JSON.stringify({error: 'Not found'}))
                    } catch (err) {
                        res.statusCode = err.code === 'ENOENT' ? 404 : 500
                        res.setHeader('Content-Type', 'application/json')
                        res.end(JSON.stringify({error: err.message}))
                    }
                })
            }
        }
    ],
    server: {
        watch: {usePolling: true},
        allowedHosts: [
            'localhost',
            '127.0.0.1',
            'quickstart-ci-components.wmcloud.org'
        ]
    }
})
