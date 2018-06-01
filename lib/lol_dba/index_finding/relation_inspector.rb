module LolDba
  class RelationInspector
    attr_accessor :model_class, :reflection_options, :reflection_name

    def initialize(model_class, reflection_options, reflection_name)
      self.model_class = model_class
      self.reflection_options = reflection_options
      self.reflection_name = reflection_name
    end

    def get_through_foreign_key(target_class, reflection_options)
      # has_many :through
      reflection = target_class.reflections[reflection_options.options[:through].to_s]

      # has_and_belongs_to_many
      reflection ||= reflection_options

      # Guess foreign key?
      if reflection.options[:foreign_key]
        reflection.options[:foreign_key]
      else
        "#{target_class.name.tableize.singularize}_id"
      end
    end

    def reflections
      model_class.reflections.stringify_keys
    end
  end
end
