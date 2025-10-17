<template>
  <div class="app">
    <RunSelector
        v-model:selected-file="selectedFile"
        :available-files="availableFiles"
        :commit="currentResult?.commit"
        @load-result="loadResult"
    />

    <div v-if="currentResult" class="results-container">
      <h1>MediaWiki Selenium Tests</h1>

      <h2>Core</h2>
      <CoreResults :core="currentResult.core"/>

      <h2>Components (skins/extensions)</h2>
      <StagesHeader/>
      <div class="components-list">
        <ComponentRow
            v-for="(component, index) in currentResult.components"
            :key="component.name"
            :component="component"
            :index="index + 1"
        />
      </div>

      <ResultsFooter :files="selectedFileData?.files || []"/>
    </div>

    <div v-else class="no-data">
      <p>No run selected</p>
    </div>
  </div>
</template>

<script setup>
import {ref, onMounted, computed} from 'vue'
import yaml from 'js-yaml'
import RunSelector from './components/RunSelector.vue'
import CoreResults from './components/CoreResults.vue'
import StagesHeader from './components/StagesHeader.vue'
import ComponentRow from './components/ComponentRow.vue'
import ResultsFooter from './components/ResultsFooter.vue'

const availableFiles = ref([])
const selectedFile = ref('')
const currentResult = ref(null)

const selectedFileData = computed(() => {
  return availableFiles.value.find(f => f.filename === selectedFile.value)
})

const loadAvailableFiles = async () => {
  try {
    const response = await fetch('/api/results/available')
    const files = await response.json()
    availableFiles.value = files
  } catch (error) {
    console.error('Failed to load files:', error)
    availableFiles.value = []
  }
}

const slugFromName = (name) => {
  return String(name)
      .replace(/^\.\//, '')
      .replace(/\/$/, '')
      .replace(/\s+/g, '-')
      .replace(/\//g, '-')
}

const loadResult = async () => {
  if (!selectedFile.value) {
    currentResult.value = null
    return
  }

  try {
    const [yamlResp, linksResp] = await Promise.all([
      fetch(`/api/results/${selectedFile.value}`),
      fetch(`/api/results/${selectedFile.value}?links=1`)
    ])

    if (!yamlResp.ok) throw new Error('Failed to fetch YAML')

    const yamlText = await yamlResp.text()
    const parsed = yaml.load(yamlText)

    if (!parsed || !Array.isArray(parsed?.components)) {
      throw new Error('Invalid YAML structure')
    }

    // Build slug
    const compLinks = new Map()
    if (linksResp.ok) {
      const meta = await linksResp.json()
      if (Array.isArray(meta?.components)) {
        for (const c of meta.components) {
          compLinks.set(c.slug, {
            html: c.html ? `/api/results/${c.html}` : null,
            ansi: c.ansi ? `/api/results/${c.ansi}` : null
          })
        }
      }
    }

    // Attach links to each component
    const ts = selectedFile.value.split('/')[0]
    parsed.components = parsed.components.map((c) => {
      const slug = slugFromName(c.name)
      const links = compLinks.get(slug) || {
        html: `/api/results/${ts}/results/${slug}/logs.ansi.html`,
        ansi: `/api/results/${ts}/results/${slug}/logs.ansi`
      }
      return {...c, links}
    })

    currentResult.value = parsed
  } catch (error) {
    console.error('Error loading result:', error)
    currentResult.value = null
  }
}

const loadLatest = async () => {
  if (availableFiles.value.length > 0) {
    selectedFile.value = availableFiles.value[0].filename
    await loadResult()
  }
}

onMounted(async () => {
  await loadAvailableFiles()
  await loadLatest()
})
</script>

<style scoped>
.results-container {
  padding: 1.5rem;
}

.no-data {
  padding: 2rem;
  text-align: center;
  color: #666;
}

h1 {
  margin-top: 0;
}
</style>
