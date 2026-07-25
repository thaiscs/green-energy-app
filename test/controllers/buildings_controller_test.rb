require "test_helper"

class BuildingsControllerTest < ActionDispatch::IntegrationTest
  test "root lists houses with links to their consumers" do
    get root_path

    assert_response :success
    assert_select "h1", "Buildings"
    assert_select "section.house .building-address", text: buildings(:sonnenhof).address
    assert_select "a[href=?]", unit_path(units(:apartment_1)), text: /A. Beispiel/
    assert_select "a[href=?]", unit_path(units(:apartment_2)), text: /B. Muster/
  end

  test "each building exposes a collapsible units panel" do
    get root_path

    assert_response :success
    assert_select "section.house[data-controller=collapse]", minimum: 6
    assert_select ".house-toggle[data-action=?]", "collapse#toggle", minimum: 6
    assert_select ".units-wrapper[data-collapse-target=panel]", minimum: 6
  end
end
