module LolDba
  class RelationInspectorFactory
    TYPES = {
      belongs_to: BelongsTo,
      has_and_belongs_to_many: HasAndBelongsToMany,
      has_many: HasMany
    }.freeze

    def self.for(type)
      TYPES[type]
    end
  end
end
