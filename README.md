# power_assert.cr

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

## ToDo

- [ ] Support `a == b && c == d`

## License

Distributed under the MIT License. Please see LICENSE for details

## Credits

- Sho Kusano [@rosylilly](https://github.com/rosylilly) for the Crystal implementation
- Takuto Wada [@twada](https://github.com/twada) for the original JavaScript implementation. power_assert.cr is inspired by [power-assert](https://www.npmjs.com/package/power-assert).
