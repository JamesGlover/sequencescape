# frozen_string_literal: true

require 'rails_helper'

feature 'Perform a tag substitution', js: true do
  let(:sample_a) { create :sample }
  let(:sample_b) { create :sample }
  let(:library_tube_a) { create :library_tube, libraries: [library_a] }
  let(:library_a) { create :library }
  let(:library_tube_b) { create :library_tube, libraries: [library_b] }
  let(:library_b) { create :library }
  let(:mx_library_tube) { create :multiplexed_library_tube }
  let(:library_type) { create :library_type }
  let(:used_tag_group) { create :tag_group }
  let(:sample_a_orig_tag) { create :tag, tag_group: used_tag_group, map_id: 1 }
  let(:sample_a_orig_tag2) { create :tag, tag_group: used_tag_group, map_id: 2 }

  let(:sample_b_orig_tag) { create :tag, tag_group: used_tag_group, map_id: 3 }
  let(:sample_b_orig_tag2) { create :tag, tag_group: used_tag_group, map_id: 4 }

  let!(:lane) { create :lane }

  let(:user) { create :user }

  background do
    create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_a, receptacle: library_tube_a
    create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_b, receptacle: library_tube_b
    create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_a, receptacle: mx_library_tube
    create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_b, receptacle: mx_library_tube
    create :aliquot, sample: sample_a, tag: sample_a_orig_tag, tag2: sample_a_orig_tag2, library: library_a, receptacle: lane
    create :aliquot, sample: sample_b, tag: sample_b_orig_tag, tag2: sample_b_orig_tag2, library: library_b, receptacle: lane
  end

  scenario 'Performing a tag swap' do
    login_user user
    visit asset_path(lane)
    click_link 'perform tag substitution'
    expect(page).to have_content(lane.name)
    fill_in('Ticket', with: '12345')
    select('Incorrect tags selected in Sequencescape.', from: 'Reason')
    find('td', text: "#{sample_a.id}: #{sample_a.sanger_sample_id}")
      .ancestor('tr')
      .select("#{sample_b_orig_tag.map_id} - #{sample_b_orig_tag.oligo}", from: 'tag_substitution[substitutions][][substitute_tag_id]')
    find('td', text: "#{sample_b.id}: #{sample_a.sanger_sample_id}")
      .ancestor('tr')
      .select("#{sample_a_orig_tag.map_id} - #{sample_a_orig_tag.oligo}", from: 'tag_substitution[substitutions][][substitute_tag_id]')
    click_button 'Substitute Tags'
    expect(page).to have_content "Asset #{lane.display_name}"
    expect(page).to have_content 'Your substitution was performed.'
    find('td', text: sample_a.name).sibling('td', text: "(#{sample_b_orig_tag.oligo})")
    find('td', text: sample_a.name).sibling('td', text: "(#{sample_a_orig_tag2.oligo})")
    find('td', text: sample_b.name).sibling('td', text: "(#{sample_a_orig_tag.oligo})")
    find('td', text: sample_b.name).sibling('td', text: "(#{sample_b_orig_tag2.oligo})")
    click_link '1 comment'
    expect(page).to have_content(
      "Tag substitution performed.
       Referenced ticket no: 12345
       Sample #{sample_a.id}: Tag changed from #{sample_a_orig_tag.oligo} to #{sample_b_orig_tag.oligo};
       Sample #{sample_b.id}: Tag changed from #{sample_b_orig_tag.oligo} to #{sample_a_orig_tag.oligo};"
    )
  end

  scenario 'Performing an invalid tag swap' do
    login_user user
    visit asset_path(lane)
    click_link 'perform tag substitution'
    expect(page).to have_content(lane.name)
    fill_in('Ticket', with: '12345')
    select('Incorrect tags selected in Sequencescape.', from: 'Reason')
    find('td', text: "#{sample_a.id}: #{sample_a.sanger_sample_id}")
      .ancestor('tr')
      .select("#{sample_b_orig_tag.map_id} - #{sample_b_orig_tag.oligo}", from: 'tag_substitution[substitutions][][substitute_tag_id]')
    find('td', text: "#{sample_a.id}: #{sample_a.sanger_sample_id}")
      .ancestor('tr')
      .select("#{sample_b_orig_tag2.map_id} - #{sample_b_orig_tag2.oligo}", from: 'tag_substitution[substitutions][][substitute_tag2_id]')
    click_button 'Substitute Tags'
    expect(page).to have_content(lane.name)
    expect(page).to have_content 'Your tag substitution could not be performed.'
    expect(page).to have_content "Tag pair #{sample_b_orig_tag.oligo}-#{sample_b_orig_tag2.oligo} features multiple times in the pool."
  end
end
