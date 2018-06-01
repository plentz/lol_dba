module LolDba
  class HasAndBelongsToMany < RelationInspector
    def relation_columns
      foreign_key = get_through_foreign_key(model_class, reflection_options)
      index_name = [association_fk, foreign_key].map(&:to_s).sort
    end

    def table_name
      table_name = reflection_options.options[:join_table]
      table_name || [model_class.table_name, reflection_name.to_s].sort.join('_')
    end

    private

    def association_fk
      association_fk = reflection_options.options[:association_foreign_key]
      association_fk || "#{reflection_name.to_s.singularize}_id"
    end
  end
end
