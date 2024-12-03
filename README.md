# Sorbet typechecking support for RSpec

This gem adds Sorbet typechecking support for RSpec so that you can use `typed: true` (or even `typed: strict`) in your specs. We provide a Tapioca DSL compiler. You still just need to add some hints to your specs to make it work.

## Setup

1. Add `rspec-sorbet-types` to your Gemfile.

2. Make sure your `sorbet/tapioca/require.rb` requires RSpec:

   ```ruby
   require "rspec"
   ```

3. Have Tapioca regenerate all gem type definitions just in case they're outdated:

   ```bash
   ./bin/tapioca gem --all
   ```

## Basic usage (without DSL compiler)

Once you've performed setup, you can use basic RSpec methods in your specs such as `RSpec.describe`, `it`, `expect`, `eq`, etc. The following code should pass typechecking:

```ruby
# typed: strict
require "rspec"
require "sorbet-runtime"

class Foo
  extend T::Sig

  sig { returns(String) }
  def name
    "foo"
  end
end

RSpec.describe Foo do
  it "works" do
    expect(described_class.new.name).to eq("foo")
  end
end
```

## Usage with DSL compiler

More advanced RSpec usage patterns require the use of the DSL compiler as well as manually-inserted type hints. These usage patterns include:

- `let`, `let!`, and `subject`.
- Methods defined inside spec blocks.
- `include`s inside spec blocks.

For example, consider this code, which fails typechecking:

```ruby
# typed: strict
require "rspec"

RSpec.describe "bar" do
  let(:number) { 100 }

  specify "let works" do
    expect(number).to eq(100)
         # ^^^^^^~~~ typecheck error:
         # Method `number` does not exist on `RSpec::Core::ExampleGroup`
  end
end
```

Definitions like `number` need to be discovered by the DSL compiler.

The DSL compiler works by requiring all your specs (by default, `spec/**/*.rb`), then inspecting the structure of your RSpec example groups. In case your specs don't follow this filename pattern, then you can customize the glob with the environment variable `SORBET_RSPEC_GLOB`.

**First**, run the DSL compiler:

```bash
./bin/tapioca dsl
# => creates sorbet/rbi/dsl/r_spec/example_groups/bar.rbi
```

**Next**, insert a type hint into every `describe`/`context`/etc. block to tell Sorbet which example group type definition it should use. Here's a full example:

```ruby
# typed: strict
require "rspec"
require "sorbet-runtime"

RSpec.describe "bar" do
  # !!! Manually insert type hint !!!
  T.bind(self, T.class_of(RSpec::ExampleGroups::Bar))

  let(:number) { 100 }

  specify "let works" do
    expect(number).to eq(100) # typecheck passes!
  end
end
```

> [!TIP]
> **What's the class name to bind to?**
>
> RSpec generates a new class for every `describe`/`context` block. It follows the pattern "RSpec::ExampleGroups::[example group slug]". The easiest way to find out the name is to put a `puts self` in the block and check what it prints.

Note that you must also type hints for any nested `describe`/`context` blocks:

```ruby
# typed: strict
require "rspec"
require "sorbet-runtime"

RSpec.describe "baz" do
  # !!! Manually insert type hint for toplevel blocks !!!
  T.bind(self, T.class_of(RSpec::ExampleGroups::Baz))

  it "works" do
    expect(1).to eq(1)
  end

  context "sub-context" do
    # !!! Manually insert type hint for sub-blocks !!!
    T.bind(self, T.class_of(RSpec::ExampleGroups::Baz::SubContext))

    let(:number) { 200 }

    specify "let works" do
      expect(number).to eq(100) # typecheck passes!
    end
  end
end
```

> [!TIP]
>
> Every time you add a new 'def', 'let', 'describe', etc (anything that changes the specs' structure), re-run `./bin/tapioca dsl`.

### Method signatures inside example groups

The `sig` method does not work by default inside example group blocks because of [Sorbet bug #8143](https://github.com/sorbet/sorbet/issues/8143):

```ruby
# typed: strict
require "rspec"
require "sorbet-runtime"

RSpec.describe "methods test" do
  T.bind(self, T.class_of(RSpec::ExampleGroups::MethodsTest))
  extend T::Sig

  sig { returns(String) }  # ERROR: Method `sig` does not exist on `T.class_of(...)`
  def name
    "Sorbet"
  end

  specify "methods work" do
    expect(name).to eq("Sorbet")
  end
end
```

Luckily, there is a workaround. Create a file _somewhere_ in your project, containing the following code, to fool the Sorbet typechecker into accepting the `sig`s (or the `rsig`s described further in the document):

```ruby
# typed: strict
require "sorbet-runtime"

# Workaround for https://github.com/sorbet/sorbet/issues/8143
if false # rubocop:disable Lint/LiteralAsCondition
  T::Sig::WithoutRuntime.sig { params(block: T.proc.bind(T::Private::Methods::DeclBuilder).void).void }
  def sig(&block)
  end

  T::Sig::WithoutRuntime.sig { params(block: T.proc.bind(T::Private::Methods::DeclBuilder).void).void }
  def rsig(&block)
  end
end
```

This file can live anywhere in your project structure as long as the Sorbet typechecker can find it. The file does not have to be `require`d by your specs.

### Typed let declarations

Even though we made Sorbet aware of the methods defined by the `let` blocks, the return type of those methods by default is `T.untyped`. If we were to try adding a `sig`, Sorbet's static analyzer will report this as an error:

```ruby
  sig { returns(Integer) }
  let(:claim_value) { 100 }

  def create_car
    Car.new
  # ^^^^^^^~~~ typecheck error:
  # Expected `Integer` but found `Car` for method result type
  end

  sig { returns(Integer) }
# ^^^^^^^^^^^^^^^^^^^^^^^^~~~ typecheck error:
# Unused type annotation. No method def before next annotation
  let(:claim_value) { 100 }

  sig { returns(String) }
  def some_value
    "42"
  end
```

Despite these errors, the signature is in fact perfectly valid at runtime. If a statement containing a signature declaration is executed, sorbet will bind that declaration to either the next method defined with `def`, or the next time `define_method` is executed. If a second signature declaration is encountered before either of these occurs, an error will be raised at runtime. A `let`, `let!`, or `subject` declaration will immediately define a method dynamically. Since there is no real value in having the above safety mechanism in the context of our tests, we can safely remove it.

While clumsy, one way to do this is by using `send` to declare the `sig` dynamically.

```ruby
  send(:sig) { T.cast(self, T::Private::Methods::DeclBuilder).returns(Integer) }
  let(:number) { 100 } # no error!
```

However, that's a bit verbose. Perhaps a better workaround is the use of `rsig`, which is just a tiny wrapper around `sig`, and provided by this gem.

```ruby
# typed: strict
require "rspec"
require "rspec/sorbet/types"

RSpec.describe "bar" do
  extend RSpec::Sorbet::Types::Sig # Extending this also extends T::Sig, does not need to be extended again in sub-contexts

  rsig { returns(Integer) }
  let(:number) { 100 }

  specify "let works" do
    expect(number).to eq(100) # typecheck passes!
  end
end
```

As with the other changes we made above, it is required to run the dsl compiler (`bin/tapioca dsl`) after adding, removing, or updating these signatures.
