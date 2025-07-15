<template>
  <div v-if="core" class="core-results">
    <div class="core-row">
      <span>./fresh_install</span>
      <span :class="core.stages.fresh_install">{{ getStatusSymbol(core.stages.fresh_install) }}</span>
    </div>
    <div class="core-row">
      <span>./selenium_tests_exist</span>
      <span :class="core.stages.selenium_tests_exist">{{ getStatusSymbol(core.stages.selenium_tests_exist) }}</span>
    </div>
    <div class="core-row">
      <span>./run_selenium_tests</span>
      <span :class="core.stages.run_selenium_tests">{{ getStatusSymbol(core.stages.run_selenium_tests) }}</span>
    </div>
  </div>
  <div v-else class="core-results no-core-data">
    <p>This run pre-dates the addition of core runs</p>
  </div>
</template>

<script setup>
import { getStatusSymbol } from '../utils/status'

const props = defineProps({
  core: {
    type: Object,
    required: false
  }
})

</script>

<style scoped>
.core-results {
  margin-bottom: 2em;
}

.core-row {
  display: flex;
  gap: 1em;
  margin-bottom: 0.25em;
}

.core-row span:first-child {
  width: 300px;
}

</style>