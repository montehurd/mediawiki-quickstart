import {defineConfig} from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs/promises'
import path from 'path'

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
                server.middlewares.use('/api/results', async (req, res) => {
                    const resultsDir = process.env.RESULTS_PATH || path.join(process.cwd(), 'ci.components', 'results')

                    const exists = async (p) => {
                        try {
                            await fs.access(p);
                            return true
                        } catch {
                            return false
                        }
                    }

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

                                const files = []
                                if (await exists(path.join(resultsDir, ansiRel))) files.push(ansiRel)
                                if (await exists(path.join(resultsDir, htmlRel))) files.push(htmlRel)

                                results.push({
                                    filename: yamlRel,
                                    timestamp: ts,
                                    displayName: new Date(parseInt(ts, 10) * 1000).toUTCString(),
                                    files
                                })
                            }

                            res.setHeader('Content-Type', 'application/json')
                            res.end(JSON.stringify(results))
                            return
                        }

                        if (req.url && req.url.startsWith('/')) {
                            const u = new URL(req.url, 'http://localhost')
                            const rel = u.pathname.slice(1)
                            const wantLinksOnly = u.searchParams.has('links') // <<<<<< NEW

                            const candidate = path.normalize(path.join(resultsDir, rel))
                            const base = path.normalize(resultsDir + path.sep)
                            if (!candidate.startsWith(base)) {
                                res.statusCode = 403
                                res.setHeader('Content-Type', 'application/json')
                                res.end(JSON.stringify({error: 'Forbidden'}))
                                return
                            }

                            if ((rel.endsWith('.yaml') || rel.endsWith('.yml')) && wantLinksOnly) {
                                const ts = rel.split('/')[0]
                                const runRoot = path.join(resultsDir, ts)

                                //aggregate files
                                const files = []
                                const ansiRel = `${ts}/${ts}.logs.ansi`
                                const htmlRel = `${ts}/${ts}.logs.ansi.html`
                                if (await exists(path.join(resultsDir, ansiRel))) files.push(ansiRel)
                                if (await exists(path.join(resultsDir, htmlRel))) files.push(htmlRel)

                                // Per-component links
                                const components = []
                                const componentsRoot = path.join(runRoot, 'results')
                                if (await exists(componentsRoot)) {
                                    const compDirents = await fs.readdir(componentsRoot, {withFileTypes: true})
                                    const compNames = compDirents
                                        .filter(d => d.isDirectory())
                                        .map(d => d.name)
                                        .sort((a, b) => a.localeCompare(b))

                                    for (const slug of compNames) {
                                        const compBase = `${ts}/results/${slug}`
                                        const compAnsi = `${compBase}/logs.ansi`
                                        const compHtml = `${compBase}/logs.ansi.html`
                                        const item = {slug}
                                        if (await exists(path.join(resultsDir, compAnsi))) item.ansi = compAnsi
                                        if (await exists(path.join(resultsDir, compHtml))) item.html = compHtml
                                        components.push(item)
                                    }
                                }

                                res.setHeader('Content-Type', 'application/json')
                                res.end(JSON.stringify({
                                    filename: rel,
                                    timestamp: ts,
                                    displayName: new Date(parseInt(ts, 10) * 1000).toUTCString(),
                                    files,
                                    components
                                }))
                                return
                            }

                            //serve the raw file (YAML/HTML/ANSI)
                            const content = await fs.readFile(candidate, 'utf-8')
                            const headers = getHeadersForFile(rel)
                            Object.entries(headers).forEach(([k, v]) => res.setHeader(k, v))
                            res.end(content)
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
