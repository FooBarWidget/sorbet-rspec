# frozen_string_literal: true
# typed: strict

module RSpec
  class << self
    sig do
      params(
        args: T.untyped,
        example_group_block: T.proc.bind(T.class_of(RSpec::Core::ExampleGroup)).void,
      ).void
    end

    def describe(*args, &example_group_block); end
  end
end

class RSpec::Core::ExampleGroup
  include ::RSpec::Matchers
  include ::RSpec::Mocks::ExampleMethods

  class << self
    sig do
      params(
        all_args: T.untyped,
        block: T.proc.bind(RSpec::Core::ExampleGroup).void,
      ).void
    end

    def it(*all_args, &block); end

    sig do
      params(
        all_args: T.untyped,
        block: T.proc.bind(RSpec::Core::ExampleGroup).void,
      ).void
    end

    def specify(*all_args, &block); end

    sig do
      params(
        args: T.untyped,
        block: T.proc.bind(RSpec::Core::ExampleGroup).void,
      ).void
    end

    def before(*args, &block); end

    sig do
      params(
        args: T.untyped,
        block: T.proc.bind(RSpec::Core::ExampleGroup).void,
      ).void
    end

    def after(*args, &block); end

    sig do
      params(
        args: T.untyped,
        block: T.proc.bind(RSpec::Core::ExampleGroup).void,
      ).void
    end

    def around(*args, &block); end
  end
end
