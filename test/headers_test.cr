require "./test_helper"
require "../src/headers"

module HTTP
  class HeadersTest < Minitest::Test
    @headers : Headers?

    def headers
      @headers ||= begin
        headers = Headers{
          ":status" => "200",
          "content-type" => "text/plain",
          "content-length" => "84",
          "Set-Cookie" => "name=cookie1",
        }
        headers.add("set-cookie", "name=cookie2")
        headers
      end
    end

    def test_accessors
      assert_raises(KeyError) { headers["unknown"] }
      assert_nil headers["unknown"]?

      assert_equal "200", headers[":status"]
      assert_equal "200", headers[":status"]?

      assert_equal "84", headers["content-length"]
      assert_equal "84", headers["content-length"]?
      assert_equal "84", headers["Content-Length"]
      assert_equal "84", headers["Content-Length"]?

      assert_equal "name=cookie1, name=cookie2", headers["set-cookie"]
      assert_equal "name=cookie1, name=cookie2", headers["set-cookie"]?

      assert_equal "name=cookie1, name=cookie2", headers["Set-Cookie"]
      assert_equal "name=cookie1, name=cookie2", headers["Set-Cookie"]?
    end

    def test_get
      assert_equal ["name=cookie1", "name=cookie2"], headers.get("set-cookie")
      assert_equal ["name=cookie1", "name=cookie2"], headers.get?("set-cookie")

      assert_equal ["name=cookie1", "name=cookie2"], headers.get("Set-Cookie")
      assert_equal ["name=cookie1", "name=cookie2"], headers.get?("Set-Cookie")

      assert_raises(KeyError) { headers.get("unknown") }
      assert_nil headers.get?("unknown")
    end
  end
end
