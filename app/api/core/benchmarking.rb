#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module Core::Benchmarking
  def self.registered(app)
    app.helpers self
  end

  def benchmark(message = nil, &block)
    yield
    #ActiveRecord::Base.benchmark("===== API benchmark (#{message || 'general'}):", Logger::ERROR, &block)
  end
end
