require 'zlib'

module JsonRecord
  class JsonField
    include AttributeMethods
    
    def initialize (record, name, schemas)
      @record = record
      @name = name
      @schemas = schemas
      @attributes = nil
      @compressed = record.class.columns_hash[name].type == :binary
    end
    
    def serialize
      if @attributes
        stripped_attributes = {}
        @attributes.each_pair{|k, v| stripped_attributes[k] = v unless v.blank?}
        json = stripped_attributes.to_json
        json = Zlib::Deflate.deflate(json) if json and @compressed
        @record[@name] = json
      end
    end
    
    def deserialize
      @attributes = {}
      @schemas.each do |schema|
        schema.fields.values.each do |field|
          @attributes[field.name] = field.multivalued? ? EmbeddedDocumentArray.new(field.type, self) : field.default
        end
      end
      
      unless @record[@name].blank?
        json = @record[@name]
        json = Zlib::Inflate.inflate(json) if @compressed
        ActiveSupport::JSON.decode(json).each_pair do |attr_name, attr_value|
          field = nil
          @schemas.each{|schema| field = schema.fields[attr_name]; break if field}
          field = FieldDefinition.new(attr_name, :type => attr_value.class) unless field
          write_attribute(field, attr_value, false, @record)
        end
      end
    end
    
    def attributes
      deserialize unless @attributes
      @attributes
    end
    
    def changes
      @record.changes
    end
    
    def changed_attributes
      @record.send(:changed_attributes)
    end
    
  end
end