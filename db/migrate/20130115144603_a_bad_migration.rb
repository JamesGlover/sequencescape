class ABadMigration < ActiveRecord::Migration
  def self.up
    if RAILS['ENV'] == 'PRODUCTION'
      say %Q{
        This migration is intentionally bad, and is not intended for a production environment.
        If you are seeing this message then the branch 'deliberately_muck_up_migrations' has
        been mistakenly merged into production. It should just be confined to this migration.

        We're going to quit now.
      }
      raise "Invalid environment for migration"
    end
    say 'This is an intentionally bad migration. Opening transaction:'
    ActiveRecord::Base.transaction do
      say 'Inside Transaction'
      uuid = Uuid.create!(:resource=>Plate.last)
      say "Created first uuid: #{uuid.external_id}, id:#{uuid.id}"
      collect = []
      say "Entering loop"
      while true
        collect << Uuid.create!(:resource=>Plate.last)
      end
      say "Outside Loop, shouldn't get here."
    end
    say 'Outside transaction: We shouldn\'t really get here'
  end

  def self.down
  end
end
