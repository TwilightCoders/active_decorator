module ActiveRecord
  module RelationDecorator
    def self.extended(base)
      ActiveDecorator.logger.debug "ActiveRecord::RelationDecorator extended by #{base.class.name}"
      return if base.respond_to?(:to_a_with_decorator)
      class << base
        def to_a_with_decorator
          to_a_without_decorator.tap do |arr|
            ActiveDecorator.decorate arr
          end
        end
        alias_method_chain :to_a, :decorator
      end
    end
  end
end
