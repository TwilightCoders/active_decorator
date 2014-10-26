# frozen_string_literal: true
require 'active_decorator/version'
require 'active_decorator/railtie'
require 'active_decorator/config'
require 'active_decorator/decorated'
require 'active_decorator/base'
require 'active_record/base_decorator'

module ActiveDecorator

  def self.decorate(obj, klass = nil)
    return if defined?(Jbuilder) && (Jbuilder === obj)
    return if obj.nil?

    if obj.is_a?(Array)
      obj.each do |r|
        ActiveDecorator.decorate r
      end
    elsif defined?(ActiveRecord) && obj.is_a?(ActiveRecord::Relation) && !obj.respond_to?(:to_a_with_decorator)
      class << obj
        def to_a_with_decorator
          to_a_without_decorator.tap do |arr|
            ActiveDecorator.decorate arr
          end
        end
        alias_method_chain :to_a, :decorator
      end
    else
      if defined?(ActiveRecord) && obj.is_a?(ActiveRecord::Base) && !obj.is_a?(ActiveDecorator::Decorated)
        obj.extend ActiveDecorator::Decorated
      end

      klass ||= obj.class

      d = ActiveDecorator.decorator_for klass
      return obj unless d
      puts "Decorating #{obj.class.name} with (#{d.name})"
      obj.extend d unless obj.is_a? d
      obj
    end
  end

  # Decorates AR model object's association only when the object was decorated.
  # Returns the association instance.
  def self.decorate_association(owner, target)
    owner.is_a?(ActiveDecorator::Decorated) ? decorate(target) : target
  end

  private

  def self.decorators
    @decorators ||= {}
  end

  # Returns a decorator module for the given class.
  # Returns `nil` if no decorator module was found.
  def self.decorator_for(model_class)
    return decorators[model_class] if decorators.key? model_class

    decorator_name = "#{model_class.name}#{ActiveDecorator.config.decorator_suffix}"
    d = decorator_name.constantize
    unless Class === d
      d.send :include, ActiveDecorator::Helpers
      decorators[model_class] = d
    else
      # Cache nil results
      decorators[model_class] = nil
    end
  rescue NameError
    puts "Couldn't find Decorator for #{model_class.name} (#{decorator_name})"
    if model_class.respond_to?(:base_class) && (model_class.base_class != model_class)
      decorators[model_class] = ActiveDecorator.decorator_for model_class.base_class
    elsif model_class < ActiveRecord::Base
      decorators[model_class] = ActiveDecorator.decorator_for model_class.superclass
    else
      nil
    end
  end

end
