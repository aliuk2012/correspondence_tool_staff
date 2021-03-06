require 'rails_helper'

describe Case::OverturnedICO::FOI do

  let(:new_case)                { described_class.new }

  # TODO: Clean up factories, I think we're creating at on of extra cases we don't need here
  let(:original_ico_appeal)     { create :ico_foi_case, original_case: original_case }
  let(:original_case)           { create :foi_case }
  let(:foi)                     { find_or_create :foi_correspondence_type }

  describe '.type_abbreviation' do
    it 'returns the correct abbreviation' do
      expect(described_class.type_abbreviation).to eq 'OVERTURNED_FOI'
    end
  end

  context 'state machine' do
    it 'uses the same state machine as standard FOI' do
      expect(described_class.state_machine_name).to eq 'foi'
    end
  end

  context 'validations' do

    context 'all mandatory fields specified' do

      context 'created in a factory' do
        it 'is valid' do
          kase = create :overturned_ico_foi
          expect(kase).to be_valid
        end
      end

      context 'created with params' do
        it 'is valid' do
          received = Date.today
          deadline = 1.month.from_now
          params = ActionController::Parameters.new(
              {
                      'original_case_id'        => original_case.id.to_s,
                      'original_ico_appeal_id'  => original_ico_appeal.id.to_s,
                      'received_date_dd'        => received.day.to_s,
                      'received_date_mm'        => received.month.to_s,
                      'received_date_yyyy'      => received.year.to_s,
                      'external_deadline_dd'    => deadline.day.to_s,
                      'external_deadline_mm'    => deadline.month.to_s,
                      'external_deadline_yyyy'  => deadline.year.to_s,
                      'reply_method'            => 'send_by_email',
                      'email'                   => 'stephen@stephenrichards.eu',
                      'ico_officer_name'        => 'Dan Dare'
              }).to_unsafe_hash
          kase = described_class.new(params)
          expect(kase).to be_valid
        end
      end
    end



    context 'received_date' do
      it 'errors if blank' do
        expect(new_case).not_to be_valid
        expect(new_case.errors[:received_date]).to eq ["can't be blank"]
      end

      it 'errors if in the future' do
        new_case.received_date = 1.day.from_now
        expect(new_case).not_to be_valid
        expect(new_case.errors[:received_date]).to eq ["can't be in the future"]
      end

      context 'too far in the past' do
        context 'new record' do
          it 'errors' do
            new_case.received_date = 29.days.ago
            expect(new_case).not_to be_valid
            expect(new_case.errors[:received_date]).to eq ['is too far in the past']
          end
        end

        context 'on create' do
          it 'errors' do
            record = described_class.create(received_date: 29.days.ago)
            expect(record.errors[:received_date]).to eq ['is too far in the past']
          end
        end

        context 'existing record' do
          it 'does not error' do
            record = described_class.create(received_date: 29.days.ago)
            allow(record).to receive(:new_record?).and_return(false)
            record.valid?
            expect(record.errors[:received_date]).to be_empty
          end
        end
      end

      it 'does not error if in the expected range' do
        new_case.received_date = 3.days.ago
        new_case.valid?
        expect(new_case.errors[:received_date]).to be_empty
      end
    end

    context 'external_deadline' do
      it 'errors if blank' do
        expect(new_case).not_to be_valid
        expect(new_case.errors[:external_deadline]).to eq ["can't be blank"]
      end

      context 'in the past' do
        context 'new record' do
          it 'errors' do
            new_case.external_deadline = 1.day.ago
            expect(new_case).not_to be_valid
            expect(new_case.errors[:external_deadline]).to eq ['cannot be in the past']
          end
        end

        context 'existing  record' do
          it 'does not error' do
            new_case.external_deadline = 3.days.ago
            allow(new_case).to receive(:new_record?).and_return(false)
            new_case.valid?
            expect(new_case.errors[:external_deadline]).to be_empty
          end
        end
      end

      context 'in the future' do
        context 'too far in the future' do
          it 'errors' do
            new_case.external_deadline = 51.days.from_now
            expect(new_case).not_to be_valid
            expect(new_case.errors[:external_deadline]).to eq ['is too far in the future']
          end
        end

        context 'within 50 days from now' do
          it 'does not error' do
            new_case.external_deadline = 49.days.from_now
            new_case.valid?
            expect(new_case.errors[:external_deadline]).to be_empty
          end
        end
      end
    end

    context 'original_ico_appeal_id' do
      context 'blank' do
        it 'errors' do
          expect(new_case).not_to be_valid
          expect(new_case.errors[:original_ico_appeal]).to eq ["can't be blank"]
        end
      end

      context 'class type' do
        context 'Case::ICO::FOI' do
          it 'is valid' do
            ico_foi = create :ico_foi_case
            new_case.original_ico_appeal = ico_foi
            new_case.valid?
            expect(new_case.errors[:original_ico_appeal]).to be_empty
          end
        end

        context 'Case::ICO::FOI' do
          it 'is invalid' do
            foi = create :case
            new_case.original_ico_appeal = foi
            new_case.valid?
            expect(new_case.errors[:original_ico_appeal]).to eq ['is not an ICO appeal for a FOI case']
          end
        end

        context 'Case::FOI' do
          it 'is invalid' do
            foi = create :foi_case
            new_case.original_ico_appeal = foi
            new_case.valid?
            expect(new_case.errors[:original_ico_appeal]).to eq ['is not an ICO appeal for a FOI case']
          end
        end
      end
    end

    context 'original_case_id' do
      context 'blank' do
        before do
          @my_thing =  Array.new
        end

        it 'errors' do
          expect(new_case).not_to be_valid
          expect(new_case.errors[:original_case]).to eq ["can't be blank"]
        end
      end

      context 'class type' do
        context 'Case::FOI' do
          it 'is valid' do
            foi = create :foi_case
            new_case.original_case_id = foi.id
            new_case.valid?
            expect(new_case.errors[:original_case_id]).to be_empty
          end
        end

        context 'Case::ICO::FOI' do
          it 'is invalid' do
            ico_foi = create :ico_foi_case
            new_case.original_case = ico_foi
            new_case.valid?
            expect(new_case.errors[:original_case]).to eq ["can't link a Overturned ICO appeal for FOI case to a ICO Appeal - FOI as a original case"]
          end
        end

        context 'Case::SAR' do
          it 'is invalid' do
            sar = create :sar_case
            new_case.original_case = sar
            new_case.valid?
            expect(new_case.errors[:original_case]).to eq ["can't link a Overturned ICO appeal for FOI case to a Non-offender SAR as a original case"]
          end
        end
      end
    end
  end

  context 'setting deadlines' do
    it 'sets the internal deadline from the external deadline' do
      Timecop.freeze(2018, 7, 23, 10, 0, 0) do
        kase = create :overturned_ico_foi,
                      original_ico_appeal: original_ico_appeal,
                      original_case: original_case,
                      received_date: Date.today,
                      external_deadline: 1.month.from_now.to_date
        expect(kase.internal_deadline).to eq 20.business_days.before(1.month.from_now).to_date
      end
    end

    it 'sets the escalation deadline to the received_date' do
      kase = create :overturned_ico_foi,
                    original_ico_appeal: original_ico_appeal,
                    original_case: original_case,
                    received_date: 0.business_days.ago,
                    external_deadline: 30.business_days.from_now
      expect(kase.escalation_deadline).to eq kase.created_at.to_date
    end
  end

  describe '#link_related_cases' do

    let(:link_case_1)             { create :foi_case }
    let(:link_case_2)             { create :foi_case }
    let(:link_case_3)             { create :foi_case }

    before(:each) do
      @kase = create :overturned_ico_foi,
                    original_ico_appeal: original_ico_appeal,
                    original_case: original_case,
                    received_date: Date.today,
                    external_deadline: 1.month.from_now.to_date

      original_case.linked_cases << link_case_1
      original_case.linked_cases << link_case_2

      original_ico_appeal.linked_cases << link_case_2
      original_ico_appeal.linked_cases << link_case_3
    end

    it 'links all the cases linked to the original case and the original_ico_appeal' do
      @kase.link_related_cases

      expect(@kase.linked_cases).to match_array [
                                                    original_case,
                                                    original_ico_appeal,
                                                    link_case_1,
                                                    link_case_2,
                                                    link_case_3
                                                ]
    end

    it 'links the overturned case to the original appeal' do
      @kase.link_related_cases
      expect(original_ico_appeal.linked_cases).to include(@kase)
    end

    it 'links the overturned case to the original case' do
      @kase.link_related_cases
      expect(original_case.linked_cases).to include(@kase)
    end

  end

  describe '#correspondence_type_for_business_unit_assignment' do
    it 'returns FOI correspondence type' do
      expect(new_case.correspondence_type_for_business_unit_assignment)
        .to eq foi
    end
  end
end
