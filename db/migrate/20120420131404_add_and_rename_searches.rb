
class Search < ActiveRecord::Base

  class FindPlateByBarcode < Search
  end
  class FindSourcePlatesByDestinationPlateBarcode < Search
  end
  class FindTubeByBarcode < Search
  end
  class FindSourceTubesByDestinationTubeBarcode < Search
  end
  class FindSourceAssetsByDestinationAssetBarcode < Search
  end
  class FindAssetByBarcode < Search
  end

end

class AddAndRenameSearches < ActiveRecord::Migration
  def self.up

    say 'Renaming and redirecting existing searches'

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute <<-EOS
        UPDATE searches
        SET name = 'Find plates by barcode', type = 'Search::FindPlateByBarcode'
        WHERE name = 'Find assets by barcode';
      EOS
      ActiveRecord::Base.connection.execute <<-EOS
        UPDATE searches
        SET name = 'Find source plates by destination plate barcode', type = 'Search::FindSourcePlatesByDestinationPlateBarcode'
        WHERE name = 'Find source assets by destination asset barcode';
      EOS

    end

    say 'Adding tube specific searches'
    Search::FindTubeByBarcode.create!(:name => 'Find tubes by barcode')
    Search::FindSourceTubesByDestinationTubeBarcode.create!(:name => 'Find source tubes by destination tube barcode')

  end

  def self.down

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute <<-EOS
        UPDATE searches
        SET name = 'Find assets by barcode', type = 'Search::FindAssetByBarcode'
        WHERE name = 'Find plates by barcode';
      EOS
      ActiveRecord::Base.connection.execute <<-EOS
        UPDATE searches
        SET name = 'Find source assets by destination asset barcode', type = 'Search::FindSourceAssetsByDestinationAssetBarcode'
        WHERE name = 'Find source plates by destination plate barcode';
      EOS
    end

    Search.find_by_name('Find tubes by barcode').destroy
    Search.find_by_name('Find source tubes by destination tube barcode').destroy

  end

end
