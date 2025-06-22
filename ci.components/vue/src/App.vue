<template>
  <div class="app">
    <RunSelector
      :available-files="availableFiles"
      v-model:selected-file="selectedFile"
      :commit="currentResult?.commit"
      @load-result="loadResult"
    />

    <div v-if="currentResult" class="results-container">
      <StagesHeader />
      <div class="components-list">
        <ComponentRow
          v-for="(component, index) in currentResult.components"
          :key="component.name"
          :component="component"
          :index="index + 1"
        />
      </div>
      <ResultsFooter
        :files="selectedFileData?.files || []"
      />
    </div>

    <div v-else class="no-data">
      <p>No run selected</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import yaml from 'js-yaml'
import RunSelector from './components/RunSelector.vue'
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

const loadResult = async () => {
  if (!selectedFile.value) {
    currentResult.value = null
    return
  }

  try {
    const response = await fetch(`/api/results/${selectedFile.value}`)
    if (!response.ok) {
      throw new Error('Failed to fetch file')
    }

    const yamlText = await response.text()
    const parsed = yaml.load(yamlText)

    if (!parsed || !parsed.components || !Array.isArray(parsed.components)) {
      throw new Error('Invalid YAML structure')
    }

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
</style>