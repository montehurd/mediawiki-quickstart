<template>
  <div class="grid-row">
    <span class="row-number">{{ index }}</span>
    <span class="component-name">{{ component.name }}</span>

    <span :class="getStatusClass( component.stages.fresh_install )">
      {{ getStatusSymbol( component.stages.fresh_install ) }}
    </span>
    <span :class="getStatusClass( component.stages.component_install )">
      {{ getStatusSymbol( component.stages.component_install ) }}
    </span>
    <span :class="getStatusClass( component.stages.selenium_tests_exist )">
      {{ getStatusSymbol( component.stages.selenium_tests_exist ) }}
    </span>
    <span :class="getStatusClass( component.stages.run_selenium_tests )">
      {{ getStatusSymbol( component.stages.run_selenium_tests ) }}
    </span>
    <span
      v-if="component.links?.html || component.links?.ansi"
      class="links-cell"
    >
      <span class="logs-trigger">
        <a
          href="#"
          @click.prevent.stop="onLogsClick"
        >
          logs
        </a>

        <div v-if="isOpen" class="logs-popover">
          <a
            v-if="component.links?.html"
            :href="component.links.html"
            rel="noopener"
            target="_blank"
          >
            html
          </a>
          <span v-if="component.links?.html && component.links?.ansi"> · </span>
          <a
            v-if="component.links?.ansi"
            :href="component.links.ansi"
            rel="noopener"
            target="_blank"
          >
            ansi
          </a>
        </div>
      </span>
    </span>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { getStatusSymbol } from '../utils/status'

const props = defineProps( {
  component: { type: Object, required: true },
  index: { type: Number, required: true },
  openLogsIndex: { type: Number, default: null }
} )

const emit = defineEmits( [ 'update:openLogsIndex' ] )

const isOpen = computed( () => props.openLogsIndex === props.index )

const onLogsClick = () => {
  emit( 'update:openLogsIndex', isOpen.value ? null : props.index )
}

const getStatusClass = ( status ) => status || 'unknown'
</script>

<style scoped>
.grid-row {
  display: grid;
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
</style>
