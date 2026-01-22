<template>
  <div class="stages-container">
    <div class="stages-legend">
      <span class="stages">Stages</span>
      <div><span class="stage">1</span> - ./fresh_install</div>
      <div><span class="stage">2</span> - ./install #COMPONENT#</div>
      <div><span class="stage">3</span> - ./selenium_tests_exist</div>
      <div><span class="stage">4</span> - ./run_selenium_tests</div>
    </div>

    <div class="stages-header-title">
      <span />
      <span />
      <span class="stages">Stages</span>
    </div>

    <div class="grid-header">
      <span />
      <span>Component</span>
      <span class="stage">1</span>
      <span class="stage">2</span>
      <span class="stage">3</span>
      <span class="stage">4</span>
    </div>
  </div>
</template>

<style scoped>

.stages-container {
  border-bottom: 2px dashed #000;
  padding-bottom: 0.7em;
  margin-bottom: 0.7em;
}

.stages-legend {
  margin-bottom: 1em;
  line-height: 1.4;
}

.stages-header-title {
  display: grid;
  grid-template-columns: 4ch 44ch 3ch 3ch 3ch 3ch;
  gap: 1ch;
  margin-bottom: 0.25em;
}

.stages-header-title .stages {
  grid-column: 3 / 7;
  text-align: center;
}

.grid-header {
  display: grid;
  grid-template-columns: 4ch 44ch 3ch 3ch 3ch 3ch;
  gap: 1ch;
  align-items: center;
  font-weight: normal;
}

.grid-header .stage {
  text-align: center;
}

.stage {color: green;}
.stages {color: green;}

</style>
