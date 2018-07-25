# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::SpecialisedField, type: :model, sample_manifest_excel: true do
  class Thing
    include SampleManifestExcel::SpecialisedField::Base
  end

  class MyPerfectClass
    include SampleManifestExcel::SpecialisedField::Base
    include SampleManifestExcel::SpecialisedField::ValueRequired
  end

  let(:library) { create :library, library_type: nil }
  let(:well) do
    create :well_with_sample_and_plate,
           aliquot_factory: :untagged_aliquot,
           aliquot_count: 1,
           aliquot_options: { library: library, sample: library.sample }
  end
  let!(:sample) { well.aliquots.first.sample }
  let!(:library_type) { create(:library_type) }
  let!(:reference_genome) { create(:reference_genome, name: 'new one') }
  let(:aliquot) { well.aliquots.first }

  describe 'Thing' do
    it 'can be initialized with a value and a sample' do
      thing = Thing.new(value: 'value', sample: sample)
      expect(thing.value).to eq 'value'
      expect(thing.sample).to eq sample
    end

    it 'knows if value is present' do
      thing = Thing.new(sample: sample)
      expect(thing.value_present?).to be_falsey
      thing.value = 'value'
      expect(thing.value_present?).to be_truthy
    end
  end

  describe 'value required' do
    it 'will produce the correct error message' do
      my_perfect_class = MyPerfectClass.new(value: nil)
      my_perfect_class.valid?
      expect(my_perfect_class.errors.full_messages).to include('My perfect class can\'t be blank')
    end
  end

  describe 'Library Type' do
    it 'will not be valid without a persisted library type' do
      expect(SampleManifestExcel::SpecialisedField::LibraryType.new(value: library_type.name, sample: sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::LibraryType.new(value: 'A new library type', sample: sample)).to_not be_valid
    end

    # Library type will probably be shifted completely onto library soon
    it 'will add the the value to the aliquot' do
      specialised_field = SampleManifestExcel::SpecialisedField::LibraryType.new(value: library_type.name)
      specialised_field.update(aliquot: aliquot)
      expect(aliquot.library_type).to eq(library_type.name)
    end

    it 'will add the the value to the library' do
      specialised_field = SampleManifestExcel::SpecialisedField::LibraryType.new(value: library_type.name)
      specialised_field.update(aliquot: aliquot)
      expect(library.library_type).to eq(library_type)
    end
  end

  describe 'Reference Genome' do
    it 'is valid, if a value was not provided' do
      expect(SampleManifestExcel::SpecialisedField::ReferenceGenome.new(sample: sample)).to be_valid
    end

    it 'will not be valid without a persisted reference genome if a value is provided' do
      expect(SampleManifestExcel::SpecialisedField::ReferenceGenome.new(value: reference_genome.name, sample: sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::ReferenceGenome.new(value: 'A new reference genome', sample: sample)).to_not be_valid
    end

    it 'will add reference genome to sample_metadata' do
      specialised_field = SampleManifestExcel::SpecialisedField::ReferenceGenome.new(value: reference_genome.name, sample: sample)
      specialised_field.update
      expect(sample.sample_metadata.reference_genome).to eq(reference_genome)
    end
  end

  describe 'Insert Size From' do
    it 'value must be a valid number greater than 0' do
      expect(SampleManifestExcel::SpecialisedField::InsertSizeFrom.new(value: 'zero')).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::InsertSizeFrom.new(value: -1)).to_not be_valid
    end

    it 'will add the value to the aliquot' do
      specialised_field = SampleManifestExcel::SpecialisedField::InsertSizeFrom.new(value: 100)
      specialised_field.update(aliquot: aliquot)
      expect(aliquot.insert_size_from).to eq(100)
    end
  end

  describe 'Insert Size To' do
    it 'value must be a valid number greater than 0' do
      expect(SampleManifestExcel::SpecialisedField::InsertSizeTo.new(value: 'zero', sample: sample)).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::InsertSizeTo.new(value: -1, sample: sample)).to_not be_valid
    end

    it 'will add the value to the aliquot' do
      specialised_field = SampleManifestExcel::SpecialisedField::InsertSizeTo.new(value: 100)
      specialised_field.update(aliquot: aliquot)
      expect(aliquot.insert_size_to).to eq(100)
    end
  end

  describe 'Sanger Plate Id' do
    let!(:sample_1) { create(:sample_with_well) }
    let!(:sample_1_plate) { sample_1.wells.first.plate }

    it 'will be valid if the value matches the sanger human barcode' do
      expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: sample_1_plate.human_barcode, sample: sample_1)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: '1234', sample: sample_1)).to_not be_valid
    end

    describe 'with foreign barcodes' do
      let!(:sample_2) { create(:sample_with_well) }

      it 'will be valid if the value matches an unused cgap foreign barcode' do
        expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: 'CGAP-ABC001', sample: sample_1)).to be_valid
      end

      it 'will not be valid if the value matches an already used cgap foreign barcode' do
        sample_1_plate.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        expect(SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: 'CGAP-ABC011', sample: sample_2)).to_not be_valid
      end

      it 'will be valid to overwrite a foreign barcode with a new foreign barcode of the same format' do
        sample_1_plate.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        field = SampleManifestExcel::SpecialisedField::SangerPlateId.new(value: 'CGAP-ABC022', sample: sample_1)
        expect(field).to be_valid
        field.update(aliquot: sample_1.wells.first.aliquots.first)
        expect(sample_1_plate.barcodes.find { |item| item[:barcode] == 'CGAP-ABC011' }).to be_nil
        expect(sample_1_plate.barcodes.find { |item| item[:barcode] == 'CGAP-ABC022' }).to_not be_nil
      end
    end
  end

  describe 'Sanger Sample Id' do
    it 'will set the sanger sample id from the sample' do
      expect(SampleManifestExcel::SpecialisedField::SangerSampleId.new(value: '1234', sample: sample).value).to eq('1234')
    end
  end

  describe 'Sanger Tube Id' do
    let!(:sample_1) { create(:sample) }
    let!(:sample_1_tube) { create(:sample_tube_with_sanger_sample_id, sample: sample_1) }

    it 'will be valid if the value matches the sanger human barcode' do
      expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: sample_1_tube.human_barcode, sample: sample_1)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: '1234', sample: sample_1)).to_not be_valid
    end

    describe 'with foreign barcodes' do
      let!(:sample_2) { create(:sample) }
      let!(:sample_tube_2) { create(:sample_tube_with_sanger_sample_id, sample: sample_2) }

      it 'will be valid if the value matches an unused cgap foreign barcode' do
        expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: 'CGAP-ABC001', sample: sample_1)).to be_valid
      end

      it 'will not be valid if the value matches an already used cgap foreign barcode' do
        sample_1_tube.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        expect(SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: 'CGAP-ABC011', sample: sample_2)).to_not be_valid
      end

      it 'will be valid to overwrite a foreign barcode with a new foreign barcode of the same format' do
        sample_1_tube.barcodes << Barcode.new(format: :cgap, barcode: 'CGAP-ABC011')
        field = SampleManifestExcel::SpecialisedField::SangerTubeId.new(value: 'CGAP-ABC022', sample: sample_1)
        expect(field).to be_valid
        field.update(aliquot: sample_1_tube.aliquots.first)
        expect(sample_1_tube.barcodes.find { |item| item[:barcode] == 'CGAP-ABC011' }).to be_nil
        expect(sample_1_tube.barcodes.find { |item| item[:barcode] == 'CGAP-ABC022' }).to_not be_nil
      end
    end
  end

  describe 'Well' do
    it 'will not be valid unless the value matches the well description' do
      expect(SampleManifestExcel::SpecialisedField::Well.new(value: 'well', sample: sample)).to_not be_valid
      expect(SampleManifestExcel::SpecialisedField::Well.new(value: sample.wells.first.map.description, sample: sample)).to be_valid
    end
  end

  describe 'Sample Ebi Accession Number' do
    it 'will not be valid if the value is different to the sample accession number' do
      expect(SampleManifestExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: '', sample: sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: 'EB123', sample: sample)).to be_valid
      sample.sample_metadata.sample_ebi_accession_number = 'EB123'
      expect(SampleManifestExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: '', sample: sample)).to be_valid
      expect(SampleManifestExcel::SpecialisedField::SampleEbiAccessionNumber.new(value: 'EB1234', sample: sample)).to_not be_valid
    end
  end

  describe 'tag sequences' do
    let!(:tag_group) { create(:tag_group) }
    let(:oligo) { 'AA' }

    describe 'tag oligo' do
      let(:tag_oligo) { SampleManifestExcel::SpecialisedField::TagOligo.new(value: oligo, sample: sample) }

      it 'will not be valid if the tag does not contain A, C, G or T' do
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'ACGT', sample: sample)).to be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'acgt', sample: sample)).to be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'acgt', sample: sample)).to be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'aatc', sample: sample)).to be_valid

        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'ACGT ACGT', sample: sample)).to_not be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'BCGT', sample: sample)).to_not be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: '-CGT', sample: sample)).to_not be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'xCGT', sample: sample)).to_not be_valid
      end

      it 'will add the value' do
        expect(tag_oligo.value).to eq(oligo)
      end

      it 'will update the aliquot and create the tag if oligo is present' do
        tag_oligo.update(aliquot: aliquot, tag_group: tag_group)
        tag = tag_group.tags.find_by(oligo: oligo)
        expect(tag).to be_present
        expect(tag.oligo).to eq(oligo)
        expect(tag.map_id).to eq(1)
        aliquot.save
        expect(aliquot.tag).to eq(tag)
      end

      it 'if oligo is not present aliquot tag should be -1' do
        tag_oligo = SampleManifestExcel::SpecialisedField::TagOligo.new(value: nil, sample: sample)
        tag_oligo.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.save
        expect(aliquot.tag_id).to eq(-1)
      end

      it 'will find the tag if it already exists' do
        tag = tag_group.tags.create(oligo: oligo, map_id: 10)
        tag_oligo.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.save
        expect(aliquot.tag).to eq(tag)
      end
    end

    describe 'tag2 oligo' do
      let(:tag2_oligo) { SampleManifestExcel::SpecialisedField::Tag2Oligo.new(value: oligo, sample: sample) }

      it 'will not be valid if the tag does not contain A, C, G or T' do
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'ACGT', sample: sample)).to be_valid
        expect(SampleManifestExcel::SpecialisedField::TagOligo.new(value: 'BCGT', sample: sample)).to_not be_valid
      end

      it 'will add the value' do
        expect(tag2_oligo.value).to eq(oligo)
      end

      it 'will update the aliquot' do
        tag2_oligo.update(aliquot: aliquot, tag_group: tag_group)
        aliquot.save
        expect(aliquot.tag2).to eq(tag_group.tags.find_by(oligo: oligo))
      end
    end
  end

  describe 'tag groups and indexes' do
    let!(:tag_group) { create(:tag_group_with_tags) }
    let!(:tag2_group) { create(:tag_group_with_tags) }
    let(:tag_group_name) { tag_group.name }
    let(:tag2_group_name) { tag2_group.name }
    let(:tag_index) { tag_group.tags[0].map_id }
    let(:tag2_index) { tag2_group.tags[0].map_id }

    describe 'tag group' do
      it 'will add the value' do
        sf_tag_group = SampleManifestExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample: sample)
        expect(sf_tag_group.value).to eq(tag_group_name)
      end

      it 'will be valid with an existing tag group name' do
        expect(SampleManifestExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample: sample)).to be_valid
      end

      it 'will not be valid without an existing tag group name' do
        expect(SampleManifestExcel::SpecialisedField::TagGroup.new(value: 'unknown', sample: sample)).to_not be_valid
      end

      it 'responds to update method but does nothing to tag on aliquot' do
        sf_tag_group = SampleManifestExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample: sample)
        expect(sf_tag_group.update(aliquot: aliquot, tag_group: nil)).to eq(nil)
        aliquot.save
        expect(aliquot.tag).to eq(nil)
      end
    end

    describe 'tag index' do
      it 'will add the value' do
        sf_tag_index = SampleManifestExcel::SpecialisedField::TagIndex.new(value: tag_index, sample: sample)
        expect(sf_tag_index.value).to eq(tag_index)
      end

      it 'will not have a valid tag index when unlinked from a tag group' do
        expect(SampleManifestExcel::SpecialisedField::TagIndex.new(value: tag_index, sample: sample)).to_not be_valid
      end

      describe 'linking' do
        let!(:sf_tag_group) { SampleManifestExcel::SpecialisedField::TagGroup.new(value: tag_group_name, sample: sample) }
        let!(:sf_tag_index) { SampleManifestExcel::SpecialisedField::TagIndex.new(value: tag_index, sample: sample) }

        before(:each) do
          sf_tag_index.sf_tag_group = sf_tag_group
        end

        it 'will have a valid tag index when linked to a tag group' do
          expect(sf_tag_index).to be_valid
        end

        it 'will not have a valid tag index when index does not match to a map_id in the tag group' do
          sf_tag_index2 = SampleManifestExcel::SpecialisedField::TagIndex.new(value: 10, sample: sample)
          sf_tag_index2.sf_tag_group = sf_tag_group
          expect(sf_tag_index2).to_not be_valid
        end

        it 'will update the aliquot with tag if its oligo is present' do
          sf_tag_index.update(aliquot: aliquot, tag_group: nil)
          tag = tag_group.tags.find_by(map_id: tag_index)
          expect(tag).to be_present
          expect(tag.oligo).to eq(tag_group.tags[0].oligo)
          expect(tag.map_id).to eq(1)
          aliquot.save
          expect(aliquot.tag).to eq(tag)
        end

        it 'if tag oligo is not present aliquot tag should be -1' do
          tag = tag_group.tags.find_by(map_id: tag_index)
          expect(tag).to be_present
          tag.oligo = nil
          tag.save
          expect(tag.oligo).to eq(nil)
          sf_tag_index.update(aliquot: aliquot, tag_group: nil)
          aliquot.save
          expect(aliquot.tag_id).to eq(-1)
        end
      end
    end

    describe 'tag2 group' do
      it 'will add the value' do
        sf_tag2_group = SampleManifestExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample: sample)
        expect(sf_tag2_group.value).to eq(tag2_group_name)
      end

      it 'will be valid with an existing tag2 group name' do
        expect(SampleManifestExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample: sample)).to be_valid
      end

      it 'will not be valid without an existing tag2 group name' do
        expect(SampleManifestExcel::SpecialisedField::Tag2Group.new(value: 'unknown', sample: sample)).to_not be_valid
      end

      it 'responds to update method but does nothing to tag2 on aliquot' do
        sf_tag2_group = SampleManifestExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample: sample)
        expect(sf_tag2_group.update(aliquot: aliquot, tag_group: nil)).to eq(nil)
        aliquot.save
        expect(aliquot.tag2).to eq(nil)
      end
    end

    describe 'tag index' do
      it 'will add the value' do
        sf_tag2_index = SampleManifestExcel::SpecialisedField::Tag2Index.new(value: tag2_index, sample: sample)
        expect(sf_tag2_index.value).to eq(tag2_index)
      end

      it 'will not have a valid tag index when unlinked from a tag group' do
        expect(SampleManifestExcel::SpecialisedField::Tag2Index.new(value: tag2_index, sample: sample)).to_not be_valid
      end

      describe 'linking' do
        let!(:sf_tag2_group) { SampleManifestExcel::SpecialisedField::Tag2Group.new(value: tag2_group_name, sample: sample) }
        let!(:sf_tag2_index) { SampleManifestExcel::SpecialisedField::Tag2Index.new(value: tag2_index, sample: sample) }

        before(:each) do
          sf_tag2_index.sf_tag2_group = sf_tag2_group
        end

        it 'will have a valid tag index when linked to a tag group' do
          expect(sf_tag2_index).to be_valid
        end

        it 'will not have a valid tag index when index does not match to a map_id in the tag group' do
          sf_tag2_index2 = SampleManifestExcel::SpecialisedField::Tag2Index.new(value: 10, sample: sample)
          sf_tag2_index2.sf_tag2_group = sf_tag2_group
          expect(sf_tag2_index2).to_not be_valid
        end

        it 'will update the aliquot with tag2 if its oligo is present' do
          sf_tag2_index.update(aliquot: aliquot, tag_group: nil)
          tag2 = tag2_group.tags.find_by(map_id: tag2_index)
          expect(tag2).to be_present
          expect(tag2.oligo).to eq(tag2_group.tags[0].oligo)
          expect(tag2.map_id).to eq(1)
          aliquot.save
          expect(aliquot.tag2).to eq(tag2)
        end

        it 'if tag2 oligo is not present aliquot tag should be -1' do
          tag2 = tag2_group.tags.find_by(map_id: tag2_index)
          expect(tag2).to be_present
          tag2.oligo = nil
          tag2.save
          expect(tag2.oligo).to eq(nil)
          sf_tag2_index.update(aliquot: aliquot, tag_group: nil)
          aliquot.save
          expect(aliquot.tag2_id).to eq(-1)
        end
      end
    end
  end
end
