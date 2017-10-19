<template>
  <div id="work-order-selector">
    <h2>Select a Work Order Type...</h2>
    <label for="work_order_type">Work Order Type</label>
      <select id="work_order_type">
        <option v-for="type in compatibleTypes" v-bind:value="type.name">{{ type.friendly_name }}</option>
      </select>
    <ol id="selected-types">
      <li v-for="type in selectedWOTypes">{{ type.friendly_name }}</li>
    </ol>
  </div>
</template>

<script>
  export default {
    data: function() {
      return {
        selectedWOTypes: []
      }
    },
    props: {
      allWOTypes: {
        type: Array,
        required: true
      }
    },
    computed: {
      compatibleTypes() {
        // Once we allow chaining of work-order-types we can
        // filter the list here, to ensure the user doesn't
        // chain together incompatible types.
        console.log('Boo')
        console.log(this.allWOTypes)
        return this.allWOTypes
      }
    }
  }
</script>

<style scoped>
  #work-order-selector {
    width: 100%;
    padding: 1em;
    border: 1px lightgray solid;
    margin-bottom: 1em;
  }
  select { @extend .form-control }
</style>
