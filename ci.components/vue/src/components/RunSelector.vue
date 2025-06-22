<template>
  <div class="app-controls">
    <select
      :value="selectedFile"
      @change="handleChange"
      class="file-selector"
    >
      <option value="">Select Run...</option>
      <option v-for="file in availableFiles" :key="file.filename" :value="file.filename">
        {{ file.displayName }}
      </option>
    </select>
    <span v-if="selectedFile" class="time-since">
      {{ timeSince }} ago
    </span>
    <span v-if="commit" class="commit-info">
      Commit <span class="commit-hash" :title="commit.message || 'No commit message'">{{ commit.hash || commit }}</span>
    </span>
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  availableFiles: {
    type: Array,
    required: true
  },
  selectedFile: {
    type: String,
    required: true
  },
  commit: [String, Object]
})

const emit = defineEmits(['update:selectedFile', 'load-result'])

// Trigger reactivity for time updates
const currentTime = ref(Date.now())
let interval

const selectedFileData = computed(() => {
  return props.availableFiles.find(f => f.filename === props.selectedFile)
})

const timeSince = computed(() => {
  if (!props.selectedFile) return ''

  // Extract Unix timestamp from filename
  const timestamp = parseInt(props.selectedFile.replace('.yaml', ''))
  const then = new Date(timestamp * 1000)
  const now = new Date(currentTime.value)
  const diffMs = now - then

  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
  const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))

  if (days > 0) {
    return `${days}d ${hours}h ${minutes}m`
  } else if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else {
    return `${minutes}m`
  }
})

const handleChange = (e) => {
  emit('update:selectedFile', e.target.value)
  emit('load-result')
}

// Update time every minute
onMounted(() => {
  interval = setInterval(() => {
    currentTime.value = Date.now()
  }, 60000)
})

onUnmounted(() => {
  clearInterval(interval)
})
</script>

<style scoped>
.app-controls {
  background: #f0f0f0;
  padding: 1rem;
  border-bottom: 2px solid #ccc;
  display: flex;
  gap: 1.5rem;
  align-items: center;
}

.file-selector {
  padding: 0.5rem;
}

.time-since {
  color: #666;
  font-size: 0.9em;
}

.commit-info {
  color: #666;
  font-size: 0.9em;
}

.commit-hash {
  cursor: help;
  text-decoration: underline;
  text-decoration-style: dotted;
}
</style>