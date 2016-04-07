require "spec"
require "../src/power_assert"

include PowerAssert

def falsey
  false
end

class PowerAssert::Example
  def one
    1
  end

  def falsey(a, b, c)
    false
  end
end

describe PowerAssert do
  describe "Simple operators" do
    it "should be fail" do
      assert 1 == 2
    end

    it "should be fail" do
      assert 1 > 2
    end
  end

  describe "Method call" do
    it "should be fail" do
      assert falsey == true
    end

    it "should be fail" do
      example = PowerAssert::Example.new

      one = 1
      two = 2
      three = 3
      assert example.falsey(one, two, three)
    end

    it "should be fail" do
      example = PowerAssert::Example.new

      assert example.one == 2
    end

    it "should be fail" do
      array = [1, 2, 3]

      assert array.any? { |n| n == 0 }.nil?
    end
  end

  describe "Condition" do
    it "should be fail" do
      a = false

      assert a ? false : true
    end
  end
end
