require 'test_helper'

class WorkOrderCollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @work_order_collection = work_order_collections(:one)
  end

  test "should get index" do
    get work_order_collections_url
    assert_response :success
  end

  test "should get new" do
    get new_work_order_collection_url
    assert_response :success
  end

  test "should create work_order_collection" do
    assert_difference('WorkOrderCollection.count') do
      post work_order_collections_url, params: { work_order_collection: { name: @work_order_collection.name } }
    end

    assert_redirected_to work_order_collection_url(WorkOrderCollection.last)
  end

  test "should show work_order_collection" do
    get work_order_collection_url(@work_order_collection)
    assert_response :success
  end

  test "should get edit" do
    get edit_work_order_collection_url(@work_order_collection)
    assert_response :success
  end

  test "should update work_order_collection" do
    patch work_order_collection_url(@work_order_collection), params: { work_order_collection: { name: @work_order_collection.name } }
    assert_redirected_to work_order_collection_url(@work_order_collection)
  end

  test "should destroy work_order_collection" do
    assert_difference('WorkOrderCollection.count', -1) do
      delete work_order_collection_url(@work_order_collection)
    end

    assert_redirected_to work_order_collections_url
  end
end
