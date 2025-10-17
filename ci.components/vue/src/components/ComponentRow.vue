<template>
  <div class="grid-row">
    <span class="row-number">{{ index }}</span>
    <span class="component-name">{{ component.name }}</span>
    <span :class="getStatusClass(component.stages.fresh_install)">{{
        getStatusSymbol(component.stages.fresh_install)
      }}</span>
    <span :class="getStatusClass(component.stages.component_install)">{{
        getStatusSymbol(component.stages.component_install)
      }}</span>
    <span :class="getStatusClass(component.stages.selenium_tests_exist)">{{
        getStatusSymbol(component.stages.selenium_tests_exist)
      }}</span>
    <span :class="getStatusClass(component.stages.run_selenium_tests)">{{
        getStatusSymbol(component.stages.run_selenium_tests)
      }}</span>

    <span class="links-cell">
      <a v-if="component.links?.html" :href="component.links.html + '#log-end'" rel="noopener" target="_blank">html</a>
      <span v-if="component.links?.html && component.links?.ansi"> · </span>
      <a v-if="component.links?.ansi" :href="component.links.ansi" rel="noopener" target="_blank">ansi</a>
    </span>
  </div>
</template>

<script setup>
import {getStatusSymbol} from '../utils/status'

defineProps({
  component: {type: Object, required: true},
  index: {type: Number, required: true}
})

const getStatusClass = (status) => status || 'unknown'
</script>

<style scoped>
.grid-row {
  display: grid;
  /* shrink the links column a bit */
  grid-template-columns: 4ch 44ch 3ch 3ch 3ch 3ch minmax(10ch, auto);
  gap: 1ch;
  align-items: center;
}

.grid-row > span:nth-child(n+3) {
  text-align: center;
}

.grid-row:hover {
  background-color: #f5f5f5;
}

.row-number {
  text-align: right;
  color: #bbb;
}

.component-name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.links-cell {
  text-align: left;
  white-space: nowrap;
  font-size: 0.78em;
  line-height: 1;
}

.links-cell a {
  text-decoration: none;
  opacity: 0.8;
  padding: 0 0.2ch;
}

.links-cell a:hover {
  text-decoration: underline;
  opacity: 1;
}

.links-cell > span {
  opacity: 0.6;
  padding: 0 0.1ch;
  font-size: 0.9em;
}
</style>
