require 'test_helper'

class PoliesControllerTest < ActionController::TestCase
  setup do
    @poly = polies(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:polies)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create poly" do
    assert_difference('Poly.count') do
      post :create, poly: { title: @poly.title }
    end

    assert_redirected_to poly_path(assigns(:poly))
  end

  test "should show poly" do
    get :show, id: @poly
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @poly
    assert_response :success
  end

  test "should update poly" do
    patch :update, id: @poly, poly: { title: @poly.title }
    assert_redirected_to poly_path(assigns(:poly))
  end

  test "should destroy poly" do
    assert_difference('Poly.count', -1) do
      delete :destroy, id: @poly
    end

    assert_redirected_to polies_path
  end
end
