#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Event::ScannedIntoLabEvent < Event
  after_create :set_qc_state_pending, :unless => :test?
  after_create :broadcast_event

  alias_method :asset, :eventful

  attr_writer :user

  def self.create_for_asset!(asset, location, user=nil)
    self.create!(
      :eventful => asset,
      :message => "Scanned into #{location.name}",
      :content => Date.today.to_s,
      :family => "scanned_into_lab",
      :location => location.name,
      :created_by => user.try(:login)||'UNKNOW'
    ).tap do |e|
      e.user = user
    end
  end

  def user
    @user ||= User.where(login:created_by).first
  end

  def read_location
    /Scanned into (.+)/.match(message)[1]
  end

  def set_qc_state_pending
    self.asset.qc_pending
  end

  def test?
    return (self.asset.qc_state == "passed" || self.asset.qc_state == "failed")
  end

  def broadcast_event
    BroadcastEvent::Reception.create!(seed:self,user:user,created_at:created_at)
  end

end
