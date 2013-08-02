class RemoveBatchRequestsWithNoBatch < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      count = 0
      BatchRequest.find_each(:joins=>['LEFT OUTER JOIN batches ON batch_id=batches.id'],:conditions=>{:batches=>{:id=>nil}}) do |br|
        if br.batch.present? or br.batch_id.nil?
          say "BatchRequest #{br.id} #{batch_id.nil? ? 'has nil batch_id' : 'has batch'}: leaving"
        else
          count += 1
          br.destroy
        end
      end
      say "#{count} BatchRequests removed"
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
