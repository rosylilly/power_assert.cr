# power_assert.cr

[![docrystal.org](http://www.docrystal.org/badge.svg)](http://wwww.docrystal.org/github.com/rosylilly/power_assert.cr)

PowerAssert provides the more powerful assertion to you.

## Usage

Very simple.

```crystal
# spec/my_lib_spec.cr

describe MyLib do
  describe ".major_version" do
    it "should be equal 1" do
      assert MyLib.major_version == 1
    end
  end
end
```

If `MyLib.major_version` is 2:

```
F

Failures:

  1) MyLib .major_version should be equal 1
     Failure/Error: assert MyLib.major_version == 1

         MyLib.major_version == 1
         |                   |  |
         |                   |  1
         |                   false
         2

     # ./spec/my_lib_spec.cr:6
```

more examples in `spec`.

:tada: Happy testing! :tada:

## Configure

- `global_indent : Int` : A indent size of assertion messages.
- `sort_by : Symbol` : Sort order of breakdowns. allowed: `:default`, `:reverse`, `:left` and `right`.
- `expand_block : Bool` : Show block's codes in the breakdown.

## Example Outputs

Run `crystal spec`.

```
FFFFFF

Failures:

  1) PowerAssert Simple operators should be fail
     Failure/Error: assert 1 == 2

         1 == 2
         | |  |
         | false
         |    |
         |    2
         1

     # ./spec/power_assert_spec.cr:23

  2) PowerAssert Simple operators should be fail
     Failure/Error: assert 1 > 2

         1 > 2
         | | |
         | false
         |   |
         |   2
         1

     # ./spec/power_assert_spec.cr:27

  3) PowerAssert Method call should be fail
     Failure/Error: assert falsey == true

         falsey == true
         |      |  |
         |      false
         |         |
         |         true
         false

     # ./spec/power_assert_spec.cr:33

  4) PowerAssert Method call should be fail
     Failure/Error: assert example.falsey(one, two, three)

         example.falsey(one, two, three)
         |       |      |    |    |
         |       false  |    |    |
         |              1    |    |
         |                   2    |
         |                        3
         #<PowerAssert::Example:0x1087a6ee0>

     # ./spec/power_assert_spec.cr:42

  5) PowerAssert Method call should be fail
     Failure/Error: assert example.one == 2

         example.one == 2
         |       |   |  |
         |       |   false
         |       |      |
         |       |      2
         |       1
         #<PowerAssert::Example:0x1087a6e60>

     # ./spec/power_assert_spec.cr:48

  6) PowerAssert Method call should be fail
     Failure/Error: assert array.any? { |n| n == 0 }.nil?

         array.any? { ... }.nil?
         |     |            |
         |     |            false
         |     false
         [1, 2, 3]

     # ./spec/power_assert_spec.cr:54

Finished in 2.16 milliseconds
6 examples, 6 failures, 0 errors, 0 pending

Failed examples:

crystal spec ./spec/power_assert_spec.cr:22 # PowerAssert Simple operators should be fail
crystal spec ./spec/power_assert_spec.cr:26 # PowerAssert Simple operators should be fail
crystal spec ./spec/power_assert_spec.cr:32 # PowerAssert Method call should be fail
crystal spec ./spec/power_assert_spec.cr:36 # PowerAssert Method call should be fail
crystal spec ./spec/power_assert_spec.cr:45 # PowerAssert Method call should be fail
crystal spec ./spec/power_assert_spec.cr:51 # PowerAssert Method call should be fail
Program terminated abnormally with error code: 256
```

## ToDo

- [ ] Support `a == b && c == d`

## License

Distributed under the MIT License. Please see LICENSE for details

## Credits

- Sho Kusano [@rosylilly](https://github.com/rosylilly) for the Crystal implementation
- Takuto Wada [@twada](https://github.com/twada) for the original JavaScript implementation. power_assert.cr is inspired by [power-assert](https://www.npmjs.com/package/power-assert).
