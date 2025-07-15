<template>
  <div class="grid-row">
    <span class="row-number">{{ index }}</span>
    <span class="component-name">{{ component.name }}</span>
    <span :class="getStatusClass(component.stages.fresh_install)">{{ getStatusSymbol(component.stages.fresh_install) }}</span>
    <span :class="getStatusClass(component.stages.component_install)">{{ getStatusSymbol(component.stages.component_install) }}</span>
    <span :class="getStatusClass(component.stages.selenium_tests_exist)">{{ getStatusSymbol(component.stages.selenium_tests_exist) }}</span>
    <span :class="getStatusClass(component.stages.run_selenium_tests)">{{ getStatusSymbol(component.stages.run_selenium_tests) }}</span>
  </div>
</template>

<script setup>
const props = defineProps({
  component: {
    type: Object,
    required: true
  },
  index: {
    type: Number,
    required: true
  }
})

const getStatusSymbol = (status) => {
  switch (status) {
    case 'pass': return '✓'
    case 'fail': return 'x'
    case 'none': return '-'
    default: return '?'
  }
}

const getStatusClass = (status) => {
  return status || 'unknown'
}
</script>

<style scoped>
.grid-row {
  display: grid;
  grid-template-columns: 4ch 44ch 3ch 3ch 3ch 3ch;
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

.pass {color: green;}
.fail {color: red;}
.none {color: green;}

</style>