# frozen_string_literal: true
# typed: strict

require "rspec/core"

module Tapioca
  module Dsl
    module Compilers
      class RSpec < Compiler
        extend T::Sig

        ConstantType = type_member { {fixed: T.class_of(::RSpec::Core::ExampleGroup)} }

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < ::RSpec::Core::ExampleGroup }
          end

          private

          sig { void }
          def require_spec_files!
            Dir.glob(spec_glob).each do |file|
              require(file)
            end
          end

          sig { returns(String) }
          def spec_glob
            ENV["SORBET_RSPEC_GLOB"] || File.join(".", "spec", "**", "*.rb")
          end
        end

        # Load all spec files during compiler definition
        require_spec_files!

        sig { override.void }
        def decorate
          klass = root.create_class(T.must(constant.name), superclass_name: T.must(constant.superclass).name)
          create_includes(klass)
          create_example_group_submodules(klass)
          create_singleton_methods(klass)
        end

        private

        sig { params(klass: RBI::Scope).void }
        def create_includes(klass)
          directly_included_modules_for(constant).each do |mod|
            klass.create_include("::#{mod}")
          end
        end

        # A method can have a signature even if the method is defined dynamically with define_method
        # The next call to def or define_method will be the one associated with the signature
        # However, an exception will be raised if we have two signature declarations in a row
        # without a method definition.
        sig { params(method_name: Symbol).returns(String) }
        def return_type_for_let_declaration(method_name)
          T::Utils.signature_for_instance_method(constant, method_name)&.return_type&.to_s || "T.untyped"
        end

        sig { params(klass: RBI::Scope).void }
        def create_example_group_submodules(klass)
          modules = directly_included_modules_for(constant).select { |mod| mod.name&.start_with?("RSpec::ExampleGroups::") }
          modules.each do |mod|
            scope = root.create_module(T.must(mod.name))
            direct_public_instance_methods_for(mod).each do |method_name|
              method_def = mod.instance_method(method_name)
              return_type = return_type_for_let_declaration(method_name)

              scope.create_method(
                method_def.name.to_s,
                parameters: compile_method_parameters_to_rbi(method_def),
                return_type:,
                class_method: false
              )
            end
          end
        end

        sig { params(klass: RBI::Scope).void }
        def create_singleton_methods(klass)
          scope = klass.create_class("<< self")
          scope.create_method(
            "let",
            parameters: [
              create_rest_param("name", type: "T.untyped"),
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )
          scope.create_method(
            "let!",
            parameters: [
              create_rest_param("name", type: "T.untyped"),
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )

          scope.create_method(
            "before",
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )

          scope.create_method(
            "after",
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )

          scope.create_method(
            "it",
            parameters: [
              create_rest_param("all_args", type: "T.untyped"),
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )

          scope.create_method(
            "specify",
            parameters: [
              create_rest_param("all_args", type: "T.untyped"),
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )

          scope.create_method(
            "subject",
            parameters: [
              create_block_param("block", type: "T.proc.bind(#{constant.name}).void")
            ]
          )

          singleton_class = constant.singleton_class
          direct_public_instance_methods_for(singleton_class).each do |method_name|
            create_method_from_def(scope, singleton_class.instance_method(method_name))
          end
        end

        sig { params(constant: Module).returns(T::Enumerable[Module]) }
        def directly_included_modules_for(constant)
          result = constant.included_modules
          result -= constant.included_modules.map do |included_mod|
            included_mod.ancestors - [included_mod]
          end.flatten
          if constant.is_a?(Class) && constant.superclass
            result -= T.must(constant.superclass).included_modules
          end
          result
        end

        sig { params(constant: Module).returns(T::Enumerable[Symbol]) }
        def direct_public_instance_methods_for(constant)
          result = constant.public_instance_methods
          constant.included_modules.each do |included_mod|
            result -= included_mod.public_instance_methods
          end
          if constant.is_a?(Class) && constant.superclass
            result -= T.must(constant.superclass).public_instance_methods
          end
          result
        end
      end
    end
  end
end
