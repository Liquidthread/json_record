module JsonRecord
  # Adds the serialized JSON behavior to ActiveRecord.
  module Serialized
    def self.included (base)
      base.class_inheritable_accessor :json_serialized_fields
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # Specify a field name that contains serialized JSON. The block will be yielded to with a
      # Schema object that can then be used to define the fields in the JSON document. A class
      # can have multiple fields that store JSON documents if necessary.
      def serialize_to_json (field_name, &block)
        field_name = field_name.to_s
        self.json_serialized_fields ||= {}
        include InstanceMethods unless include?(InstanceMethods)
        schema = Schema.new(self, field_name)
        field_schemas = json_serialized_fields[field_name]
        if field_schemas
          field_schemas = field_schemas.dup
        else
          field_schemas = []
        end
        json_serialized_fields[field_name] = field_schemas
        field_schemas << schema
        block.call(schema) if block
      end
      
      # Get the field definition of the JSON field from the schema it is defined in.
      def json_field_definition (name)
        field = nil
        if json_serialized_fields
          name = name.to_s
          json_serialized_fields.values.flatten.each{|schema| field = schema.fields[name]; break if field}
        end
        return field
      end
    end
    
    module InstanceMethods
      def self.included (base)
        base.before_save :serialize_json_attributes
        base.alias_method_chain :reload, :serialized_json
        base.alias_method_chain :attributes, :serialized_json
      end
      
      # Get the JsonField objects for the record.
      def json_fields
        unless @json_fields
          @json_fields = {}
          json_serialized_fields.each_pair do |name, schemas|
            @json_fields[name] = JsonField.new(self, name, schemas)
          end
        end
        @json_fields
      end
      
      def reload_with_serialized_json (*args)
        @json_fields = nil
        reload_without_serialized_json(*args)
      end
      
      def attributes_with_serialized_json
        attrs = json_attributes.reject{|k,v| !json_field_names.include?(k)}
        attrs.merge!(attributes_without_serialized_json)
        json_serialized_fields.keys.each{|name| attrs.delete(name)}
        return attrs
      end
      
      protected
      
      # Returns a hash of all the JsonField objects merged together.
      def json_attributes
        attrs = {}
        json_fields.values.each do |field|
          attrs.merge!(field.json_attributes)
        end
        attrs
      end
      
      def json_field_names
        @json_field_names = json_serialized_fields.values.flatten.collect{|s| s.fields.keys}.flatten
      end
      
      # Read a field value from a JsonField
      def read_json_attribute (json_field_name, field)
        json_fields[json_field_name].read_attribute(field, self)
      end
      
      # Write a field value to a JsonField
      def write_json_attribute (json_field_name, field, value, track_changes)
        json_fields[json_field_name].write_attribute(field, value, track_changes, self)
      end
      
      # Serialize the JSON in the record into JsonField objects.
      def serialize_json_attributes
        json_fields.values.each{|field| field.serialize} if @json_fields
      end
      
      # Write out the JSON representation of the JsonField objects to the database fields.
      def deserialize_json_attributes
        json_fields.values.each{|field| field.deserialize} if @json_fields
      end
    end
  end
end
