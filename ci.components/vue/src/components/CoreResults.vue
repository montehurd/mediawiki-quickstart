<template>
  <div
    v-if="core"
    class="core-results"
  >
    <div class="core-row">
      <span>./fresh_install</span>
      <span :class="core.stages.fresh_install">{{ getStatusSymbol( core.stages.fresh_install ) }}</span>
    </div>
    <div class="core-row">
      <span>./selenium_tests_exist</span>
      <span :class="core.stages.selenium_tests_exist">{{ getStatusSymbol( core.stages.selenium_tests_exist ) }}</span>
    </div>
    <div class="core-row">
      <span>./run_selenium_tests</span>
      <span :class="core.stages.run_selenium_tests">{{ getStatusSymbol( core.stages.run_selenium_tests ) }}</span>
    </div>
    <div class="logs-row">
      <div class="core-row">
        <span v-if="core.links" class="links-cell">
          <span class="logs-trigger">
            <span class="core-logs"><a href="#" @click.prevent.stop="onLogsClick">logs</a></span>
            <div v-if="isOpen" class="logs-popover">
              <a :href="core.links.html" rel="noopener" target="_blank">html</a>
              <span> · </span>
              <a :href="core.links.ansi" rel="noopener" target="_blank">ansi</a>
            </div>
          </span>
        </span>
      </div>
    </div>
  </div>
  <div
    v-else
    class="core-results no-core-data"
  >
    <p>This run pre-dates the addition of core runs</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { getStatusSymbol } from '../utils/status'

const props = defineProps( {
  core: {
    type: Object,
    required: false
  }
} )

const isOpen = ref(false)

const onLogsClick = () => {
  isOpen.value = !isOpen.value
}

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

.logs-row {
  margin-top: 0.5em;
}

.core-logs {
  font-size: x-large;
}

.logs-popover {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  left: calc(25% + 0.5ch);
  padding: 0.25rem 0.4rem;
  border-radius: 3px;
  background: #fff;
  border: 1px solid #ddd;
  box-shadow: 0 2px 4px rgba( 0, 0, 0, 0.1 );
  z-index: 10;
  white-space: nowrap;
}

</style>
