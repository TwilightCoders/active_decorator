require 'active_decorator/version'
require 'active_decorator/railtie'
require 'active_decorator/base'
require 'active_record/base_decorator'
require 'active_record/relation_decorator'

module ActiveDecorator

  def self.decorate(obj, klass = nil)
    return if obj.nil?

    if Array === obj
      obj.each do |r|
        ActiveDecorator.decorate r
      end

    else

      klass ||= obj.class
      # binding.pry if klass < ActiveRecord::Base
      # ActiveDecorator.decorate obj, klass.superclass if klass.superclass

      d = decorator_for klass
      return obj unless d
      logger.debug "Decorating #{obj.class.name} with (#{d.name})"
      obj.extend d unless obj.is_a? d
      obj
    end
  end

  private

  def self.decorators
    @decorators ||= {}
  end

  def self.logger
    @logger ||= defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
  end

  def self.decorator_for(model_class)
    return decorators[model_class] if decorators.key? model_class

    decorator_name = "#{model_class.name}Decorator"
    #binding.pry# if model_class.name == 'Submission::ActiveRecord_AssociationRelation'
    d = decorator_name.constantize
    unless Class === d
      d.send :include, ActiveDecorator::Base
      decorators[model_class] = d
    else
      decorators[model_class] = nil
    end
  rescue NameError
    logger.debug "Couldn't find Decorator for #{model_class.name} (#{decorator_name})"
    decorators[model_class] = if model_class.superclass
                                decorator_for model_class.superclass
                              else
                                nil
                              end
  end
end
