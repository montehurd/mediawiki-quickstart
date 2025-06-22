<template>
  <div class="footer-container">
    <div v-if="files.length > 0">
      Artifacts
      <span v-for="(file, index) in files" :key="file">
        <a class="footer-link" :href="`/api/results/${file}`">{{ getExtension(file) }}</a>
      </span>
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
</style>