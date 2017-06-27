require 'rails_helper'

describe ResponseUploaderService do

  let(:upload_group)          { '20170615102233' }
  let(:responder)             { create :responder }
  let(:kase)                  { create(:accepted_case, responder: responder) }
  let(:filename)              { "#{Faker::Internet.slug}.jpg" }
  let(:uploads_key)           { "uploads/#{kase.id}/responses/#{filename}" }
  let(:destination_key)       { "#{kase.id}/responses/#{upload_group}/#{filename}" }
  let(:destination_path)      { "correspondence-staff-case-uploads-testing/#{destination_key}" }
  let(:uploads_object)        { instance_double(Aws::S3::Object, 'uploads_object') }
  let(:public_url)            { "#{CASE_UPLOADS_S3_BUCKET.url}/#{URI.encode(destination_key)}" }
  let(:destination_object)    { instance_double Aws::S3::Object, 'destination_object', public_url: public_url }
  let(:leftover_files)        { [] }
  let(:rus)                   { ResponseUploaderService.new(kase, kase.responder, params, action) }
  let(:state_machine)         { double CaseStateMachine }

  let(:params) do
    ActionController::Parameters.new(
      {
        "type"=>"response",
        "uploaded_files"=>[uploads_key],
        "id"=>kase.id.to_s,
        "controller"=>"cases",
        "action"=>"upload_responses"}
    )
  end



  before(:each) do
    ENV['TZ'] = 'UTC'
    Timecop.freeze Time.new(2017, 6, 15, 10, 22, 33)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(uploads_key)
                                       .and_return(uploads_object)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                       .with(destination_key)
                                       .and_return(destination_object)
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:objects)
                                       .with(prefix: "uploads/#{kase.id}")
                                       .and_return(leftover_files)
    allow(uploads_object).to receive(:move_to).with(destination_path)
  end

  after(:each) do
    Timecop.return
    ENV['TZ'] = nil
  end


  describe '#upload!' do

    before(:each) { ActiveJob::Base.queue_adapter = :test }

    context 'action upload' do

      let(:action) { 'upload' }


      it 'creates a new case attachment' do
          expect{ rus.upload! }.to change { kase.reload.attachments.count }.by(1)
      end

      it 'moves uploaded object to destination path' do
        rus.upload!
        expect(uploads_object).to have_received(:move_to).with(destination_path)
      end

      it 'makes the attachment type a response' do
        rus.upload!
        expect(kase.attachments.first.type).to eq 'response'
      end

      it 'gives a result of :ok' do
        rus.upload!
        expect(rus.result).to eq :ok
      end

      it 'calls add_responses! for non flagged cases' do
        expect(kase).to receive(:state_machine).and_return(state_machine)
        expect(state_machine).to receive(:add_responses!)
        rus.upload!
      end


      context 'pdf job queueing' do

        it 'queues a job for each file' do
          response_attachments = [
            create(:correspondence_response, case_id: kase.id),
            create(:correspondence_response, case_id: kase.id)
          ]
          allow(rus).to receive(:create_attachments).and_return(response_attachments)
          expect(PdfMakerJob).to receive(:perform_later).with(response_attachments.first.id)
          expect(PdfMakerJob).to receive(:perform_later).with(response_attachments.last.id)
          rus.upload!
        end
      end

      context 'files removed from dropzone upload' do
        let(:leftover_files) do
          [instance_double(Aws::S3::Object, delete: nil)]
        end

        it 'removes any files left behind in uploads' do
          rus.upload!
          leftover_files.each do |object|
            expect(object).to have_received(:delete)
          end
        end
      end

      context 'an attachment already exists with the same name' do
        let(:attachment) do
          create :case_response,
                 key: destination_key,
                 case: kase
        end

        before do
          attachment
        end

        it 'does not create a new case_attachment object' do
          expect{
            rus.upload!
          }.not_to change{ CaseAttachment.count }
        end

        it 'returns :error' do
          expect(rus.upload!).to eq :error
        end
      end

      context 'uploading invalid attachment type' do
        before { allow(uploads_object).to receive(:move_to).with("correspondence-staff-case-uploads-testing/#{kase.id}/responses/20170615102233/invalid.exe") }

        let(:uploads_key) do
          "uploads/#{kase.id}/responses/20170615102233/invalid.exe"
        end

        it 'renders the new_response_upload page' do
          rus.upload!
          expect(rus.result).to eq :error
        end

        it 'does not create a new case attachment' do
          expect { rus.upload! }.to_not change { kase.reload.attachments.count }
        end
      end

      context 'No valid files to upload' do
        it 'returns a result of :blank' do
          params.delete('uploaded_files')
          rus.upload!
          expect(rus.result).to eq :blank
        end
      end

    end
  end

  context 'action upload-flagged' do

    let(:action)  { 'upload-flagged' }

    it 'calls add_response_to_flagged_case! on state machine' do
      expect(kase).to receive(:state_machine).and_return(state_machine)
      expect(state_machine).to receive(:add_response_to_flagged_case!)
      rus.upload!
    end
  end

  context 'action upload-approve' do

    let(:action)  { 'upload-approve' }

    it 'calls add_response_to_flagged_case! on state machine' do
      expect(kase).to receive(:state_machine).and_return(state_machine)
      expect(state_machine).to receive(:upload_response_and_approve!)
      rus.upload!
    end
  end

  context 'action upload-revert' do
    let(:action)  { 'upload-revert' }

    it 'calls upload_response_and_return_for_redraft! on state_machine' do
      expect(kase).to receive(:state_machine).and_return(state_machine)
      expect(state_machine).to receive(:upload_response_and_return_for_redraft!)
      rus.upload!
    end
  end

end

