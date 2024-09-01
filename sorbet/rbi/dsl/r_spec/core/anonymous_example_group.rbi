# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `RSpec::Core::AnonymousExampleGroup`.
# Please instead update this file by running `bin/tapioca dsl RSpec::Core::AnonymousExampleGroup`.


class RSpec::Core::AnonymousExampleGroup < RSpec::Core::ExampleGroup
  class << self
    sig { params(args: T.untyped, block: T.proc.bind(RSpec::Core::AnonymousExampleGroup).void).returns(T.untyped) }
    def after(*args, &block); end

    sig { params(args: T.untyped, block: T.proc.bind(RSpec::Core::AnonymousExampleGroup).void).returns(T.untyped) }
    def before(*args, &block); end

    sig { params(all_args: T.untyped, block: T.proc.bind(RSpec::Core::AnonymousExampleGroup).void).returns(T.untyped) }
    def it(*all_args, &block); end

    sig { params(name: T.untyped, block: T.proc.bind(RSpec::Core::AnonymousExampleGroup).void).returns(T.untyped) }
    def let(*name, &block); end

    sig { params(all_args: T.untyped, block: T.proc.bind(RSpec::Core::AnonymousExampleGroup).void).returns(T.untyped) }
    def specify(*all_args, &block); end
  end
end
