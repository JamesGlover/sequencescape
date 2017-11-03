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
        allWOTypes: [],
        lastErrof: null
      };
    },
    components: {
      HotTable,
      WorkOrderTypesSelector
    },
    beforeMount() {
      created() {
        this.$http.get('work_order_types')
          .then(response => {
            this.allWOTypes = response.data
            this.loading = false
          })
          .catch(e => {
            this.lastError = e
            this.loading = false
          })
      }
    }
  }
</script>

<style scoped>

</style>
