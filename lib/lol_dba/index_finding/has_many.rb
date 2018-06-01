module LolDba
  class HasMany < RelationInspector
    def relation_columns
      # has_many tables are threaten by the other side of the relation
      return nil unless through && reflections[through.to_s]

      # FIXME: currently we don't support :through =>
      # :another_regular_has_many_and_non_through_relation
      if (association_foreign_key = find_association_fk).present?
        [association_foreign_key, foreign_key].map(&:to_s).sort
      end
    end

    def table_name
      through_class.table_name
    end

    private

    def find_association_fk
      if (source = reflection_options.options[:source])
        association_reflection = through_reflections[source.to_s]
        return nil if association_reflection.options[:polymorphic]
        get_through_foreign_key(association_reflection.klass, reflection_options)
      elsif belongs_to_reflections = through_reflections[reflection_name.singularize]
        # go to joining model through has_many and find belongs_to
        belongs_to_reflections.options[:foreign_key]
      end
    end

    def through_class
      reflections[through.to_s].klass
    end

    def through
      reflection_options.options[:through]
    end

    def foreign_key
      get_through_foreign_key(model_class, reflection_options)
    end

    def through_reflections
      through_class.reflections.stringify_keys
    end
  end
end
