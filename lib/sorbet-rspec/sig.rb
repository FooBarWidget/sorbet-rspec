# typed: true

module SorbetRspec
  module Sig
    include Kernel

    def self.extended(sub)
      super
      sub.extend(T::Sig)
    end

    T::Sig::WithoutRuntime.sig { params(decl: T.proc.bind(T::Private::Methods::DeclBuilder).void).void }
    def rsig(&decl)
      # It would be better if we could simply use the name "sig", but Sorbet falsely reports that as an overload
      send(:sig, &decl)
    end
  end
end
