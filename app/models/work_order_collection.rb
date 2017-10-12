# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# A work order collection represents a group of work orders made at the same time
# It is used to:
# 1) Provide a convenient means for users to monitor/ask questions about specific batches of work
# 2) Avoids the need to globally unique identifiers to describe pools/pre-capture-pools
class WorkOrderCollection < ApplicationRecord
end
