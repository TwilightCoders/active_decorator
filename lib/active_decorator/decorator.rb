require 'singleton'
require 'active_decorator/helpers'

module ActiveDecorator
  class Decorator
    include Singleton

    def initialize
      @@decorators = {}
    end

    def decorate(obj)
      return if obj.nil?

      if Array === obj
        obj.each do |r|
          decorate r
        end
      elsif defined?(ActiveRecord) &&
            obj.is_a?(ActiveRecord::Relation) &&
            !obj.respond_to?(:to_a_with_decorator)
        class << obj
          def to_a_with_decorator
            to_a_without_decorator.tap do |arr|
              ActiveDecorator::Decorator.instance.decorate arr
            end
          end
          alias_method_chain :to_a, :decorator
        end
      else
        d = decorator_for obj.class
        unless !d || obj.is_a?(d)
          obj.extend d
          (class << obj; self; end).class_eval do
            obj.class.reflect_on_all_associations.map(&:name).each do |assoc|
              define_method(assoc) do |*args|
                associated = super(*args)
                ActiveDecorator::Decorator.instance.decorate associated, true
              end
            end
          end if obj.class.respond_to? :reflect_on_all_associations
        end
        obj
      end
    end

    private

    def decorator_for(model_class)
      return @@decorators[model_class] if @@decorators.key? model_class

      decorator_name = "#{model_class.name}Decorator"
      d = decorator_name.constantize
      unless Class === d
        d.send :include, ActiveDecorator::Helpers
        @@decorators[model_class] = d
      else
        @@decorators[model_class] = nil
      end
    rescue NameError
      if model_class < ActiveRecord::Base
        decorator_for model_class.superclass
      else
        @@decorators[model_class] = nil
      end
    end
  end
end
