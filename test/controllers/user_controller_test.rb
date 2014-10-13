require 'test_helper'

class UserControllerTest < ActionController::TestCase
  test "should get sign_in" do
    get :sign_in
    assert_response :success
  end

  test "should get register" do
    get :register
    assert_response :success
  end

end
