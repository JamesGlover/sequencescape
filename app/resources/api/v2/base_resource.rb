# frozen_string_literal: true

module Api
  module V2
    # Provides extensions to JSONAPI::Resource as well as global behaviour
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaseResource < JSONAPI::Resource
      abstract

      # Loaded on the base class so that they can be loaded globally.
      Purpose.descendants.each do |subclass|
        model_hint model: subclass, resource: :purpose
      end
      Plate.descendants.each do |subclass|
        model_hint model: subclass, resource: :plate
      end
      Tube.descendants.each do |subclass|
        model_hint model: subclass, resource: :tube
      end
      Request.descendants.each do |subclass|
        model_hint model: subclass, resource: :request
      end

      # This extension allows the immutable property to be used on attributes/relationships.
      # Immutable properties are those which can be set at creation, but can't be subsequently
      # updated.
      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:immutable] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:immutable] }.keys
      end

      # Eager load specified models by default. Useful when attributes are
      # dependent on an associated model.
      def self.default_includes(*inclusions)
        @default_includes = inclusions.freeze
      end

      def self.inclusions
        @default_includes || [].freeze
      end

      def self.records(*args)
        if @default_includes.present?
          super.preload(*inclusions)
        else
          super
        end
      end

      # Fixes https://github.com/cerebris/jsonapi-resources/issues/1160
      # Type is being passed straight through for polymorphic relationships, and
      # isn't correctly converted. The fix proposed in the issue won't actually
      # work as the method it relies on has been removed.
      # Here we:
      # - Lookup the resource class
      # - Link that back to the Rails model
      # - Then fetch the base class (as foreign keys link based on the table name)
      def _replace_polymorphic_to_one_link(relationship_type, key_value, key_type, _options)
        key_type_class = self.class.resource_klass_for(key_type.to_s)._model_class.base_class
        relationship = self.class._relationships[relationship_type.to_sym]

        send("#{relationship.foreign_key}=", {type: key_type_class, id: key_value})
        @save_needed = true

        :completed
      end
    end
  end
end
