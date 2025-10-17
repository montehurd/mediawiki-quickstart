<template>
  <div class="footer-container">
    <div v-if="files.length > 0">
      Artifacts
      <span v-for="(file, index) in files" :key="file">
        <a :href="`/api/results/${file}`" class="footer-link">{{ getExtension(file) }}</a>
      </span>
      <div class="footer-note">
        <ul>
          <li>"log.ansi" - console output of the run, click to download then use "cat" in your terminal to view</li>
          <li>"log.ansi.html" - html version of run console output, click to view</li>
          <li>"yaml" - data file containing results of run</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  files: {
    type: Array,
    default: () => []
  }
})

const getExtension = (filename) => {
  const match = filename.match(/^\d+\.(.+)$/)
  return match ? match[1] : filename
}
</script>

<style scoped>
.footer-container {
  margin-top: 2.5em;
  color: green;
}

.footer-link {
  display: block;
  padding-top: 0.5em;
  color: #000;
}

.footer-note {
  margin: 1em;
  margin-left: 0;
  color: #000;
}
</style>
