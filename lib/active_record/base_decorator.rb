module ActiveRecord
  module BaseDecorator
    def self.extended(base)
      ActiveDecorator.logger.debug "ActiveRecord::BaseDecorator extended by #{base.class.name}"
      class << base
        self.reflect_on_all_associations.map(&:name).each do |assoc|
          ActiveDecorator.logger.debug "Reflecting on #{assoc}"
          feature = :decorations
          with_method    = "#{assoc}_with_#{feature}"
          without_method = "#{assoc}_without_#{feature}"

          return if method_defined?(with_method) || assoc.blank?

          define_method(with_method) do |*args, &block|
            associated = send(without_method, *args, &block)
            ActiveDecorator.decorate associated
          end
          alias_method_chain(assoc, feature)
        end
      end if base.class.respond_to? :reflect_on_all_associations
    end
  end
end
