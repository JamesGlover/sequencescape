<template>
  <div id="work-order-collection-creation-app">
    <WorkOrderTypesSelector v-bind:allWOTypes="allWOTypes"></WorkOrderTypesSelector>
    <HotTable :root="root" :settings="hotSettings"></HotTable>
  </div>
</template>

<script>
  import HotTable from 'vue-handsontable-official'
  import WorkOrderTypesSelector from './components/work_order_types_selector.vue'
  import Vue from 'vue'

  const defaultColumns = ['Asset ID', 'Asset Name', 'Sample Name', 'Study', 'Project']

  export default {
    data: function() {
      return {
        root: 'test-hot',
        hotSettings: {
          data: [
            ['12345', 'DN23456:A1','Sample A','My Study','My Project'],
            ['23456','DN23456:B1','Sample A','My Study','My Project']
          ],
          colHeaders: defaultColumns
        },
        allWOTypes: [
          { friendly_name: "Boris", name: "boris" },
          { friendly_name: "Joe", name: "joe" }
        ]
      };
    },
    components: {
      HotTable,
      WorkOrderTypesSelector
    },
    beforeMount() {
      // Import data from the root element
      this.allWOTypes = JSON.parse(this.$el.attributes['data-work-order-types'].value);
    }
  }
</script>

<style scoped>

</style>
