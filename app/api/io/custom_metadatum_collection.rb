# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class ::Io::CustomMetadatumCollection < ::Core::Io::Base
  set_model_for_input(::CustomMetadatumCollection)
  set_json_root(:custom_metadatum_collection)

  define_attribute_and_json_mapping("
             metadata <=> metadata
             user <= user
             asset <= asset
  ")
end
