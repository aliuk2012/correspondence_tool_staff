class CreateOverturnedICOCaseService

  attr_reader :original_ico_appeal, :overturned_ico_case

  def initialize(ico_appeal_id)
    @original_ico_appeal = Case::Base.find(ico_appeal_id)
    @error = false
  end

  def error?
    @error
  end

  def success?
    !@error
  end

  def call
    overturned_klass = case @original_ico_appeal.type
                        when 'Case::ICO::FOI'
                          Case::OverturnedICO::FOI
                         when 'Case::ICO::SAR'
                           Case::OverturnedICO::SAR
                         else
                           @original_ico_appeal.errors.add(:base, 'Invalid ICO appeal case type')
                           @error = true
                       end
    if success?
      original_case                                 = @original_ico_appeal
      @overturned_ico_case                          = overturned_klass.new
      @overturned_ico_case.subject                  = original_case.subject
      @overturned_ico_case.original_ico_appeal_id   = @original_ico_appeal.id
      @overturned_ico_case.original_case_id         = original_case.id
    end
  end


end