require 'rom/factory/builder'

module ROM
  module Factory
    class DSL < BasicObject
      attr_reader :_name, :_relation, :_schema, :_factories

      def initialize(name, relation:, factories:, &block)
        @_name = name
        @_relation = relation
        @_factories = factories
        @_schema = {}
        yield(self)
      end

      def call
        ::ROM::Factory::Builder.new(_schema, _relation)
      end

      def create(name, *args)
        _factories[name, *args]
      end

      def sequence(meth, &block)
        if _relation.schema.attributes.map(&:name).include?(meth)
          define_sequence_method(meth, block)
        end
      end

      def timestamps
        created_at { ::Time.now }
        updated_at { ::Time.now }
      end

      def fake(*args)
        ::ROM::Factory.fake(*args)
      end

      private

      def method_missing(meth, *args, &block)
        if _relation.schema.attributes.map(&:name).include?(meth)
          define_regular_method(meth, *args, &block)
        else
          super
        end
      end

      def define_sequence_method(meth, block)
        _schema[meth] = attributes::Callable.new(attributes::Sequence.new(&block))
      end

      def define_regular_method(meth, *args, &block)
        if block
          _schema[meth] = attributes::Callable.new(block)
        else
          _schema[meth] = attributes::Regular.new(*args)
        end
      end

      def attributes
        ::ROM::Factory::Attributes
      end
    end

    def self.fake(type, *args)
      api = Faker.const_get(Dry::Core::Inflector.classify(type.to_s))
      meth, *rest = args

      if meth.is_a?(Symbol)
        api.public_send(meth, *rest)
      else
        api.public_send(type, *args)
      end
    end
  end
end
