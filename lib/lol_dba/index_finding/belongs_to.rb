module LolDba
  class BelongsTo < RelationInspector
    def relation_columns
      if reflection_options.options[:polymorphic]
        poly_type = "#{reflection_options.name}_type"
        poly_id = "#{reflection_options.name}_id"
        [poly_type, poly_id].sort
      else
        foreign_key = non_polymorphic_fk

        # not a clue why rails 4.1+ creates this left_side_id thing
        foreign_key == 'left_side_id' ? nil : foreign_key.to_s
      end
    end

    def table_name
      class_name.table_name
    end

    private

    def non_polymorphic_fk
      foreign_key = reflection_options.options[:foreign_key]
      foreign_key ||= if reflection_options.respond_to?(:primary_key_name)
                        reflection_options.primary_key_name
                      else
                        reflection_options.foreign_key
        end
    end
  end
end
