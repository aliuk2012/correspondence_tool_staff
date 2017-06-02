module CasesHelper

  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ','
  end

  #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def action_button_for(event)
    case event
    when :assign_responder
      link_to I18n.t('common.case.assign'),
              new_case_assignment_path(@case),
              id: 'action--assign-to-responder',
              class: 'button'
    when :add_responses, :add_response_to_flagged_case
      link_to t('common.case.upload_response'),
              new_response_upload_case_path(@case),
              id: 'action--upload-response',
              class: 'button'
    when :respond
      link_to t('common.case.respond'),
              respond_case_path(@case),
              id: 'action--mark-response-as-sent',
              class: 'button'
    when :reassign_approver
      link_to 'Re-assign to me',
              reassign_approver_case_path(@case),
              it: 'action--reassign-approver',
              class: 'button',
              method: 'patch'
    when :approve
      link_to t('common.case.clear_response'),
              approve_response_case_path(@case),
              id: 'action--approve',
              class: 'button'
    when :close
      link_to I18n.t('common.case.close'),
              close_case_path(@case),
              id: 'action--close-case',
              class: 'button', method: :get
    end
  end
  #rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  def show_hide_message(kase)

    (preview_copy, remaining_copy) = kase.message_extract

    if remaining_copy.nil?
      kase.message
    else
      content_tag(:span, preview_copy, class: 'ellipsis-preview') +
          content_tag(:span,'...', class:'ellipsis-delimiter js-hidden') +
          content_tag(:span, remaining_copy,  class: 'ellipsis-complete js-hidden' ) +
          link_to('Show more', '#', class: 'ellipsis-button js-hidden')
    end
  end

  def attachment_download_link(kase, attachment)
    link_to t('common.case.download_link_html', filename: attachment.filename),
            download_case_case_attachment_path(kase, attachment),
            class: 'download'

  end

  def attachment_preview_link(attachment)
    if attachment.preview_key != nil
      link_to "View",
                 case_case_attachment_path(attachment.case, attachment),
                 {target: "_blank", class: "view"}
    else
      ''
    end
  end

  def attachment_remove_link(kase, attachment)
    link_to t('common.case.remove_link_html', filename: attachment.filename),
            case_case_attachment_path(kase, attachment),
            {method: :delete, class:"delete",
            remote: true,
            data: {
              confirm: "Are you sure you want to remove #{attachment.filename}?"
            }}
  end

  def exemptions_checkbox_selector(exemption, kase)
    if kase.exemptions.map(&:id).include?(exemption.id)
      'selected'
    else
      ''
    end
  end

  def case_attachments_visible_for_case?(kase)
    return false if @case.attachments.blank?
    case kase.current_state
    when 'drafting', 'awaiting_dispatch'
      policy(@case).can_add_attachment?
    else
      true
    end
  end
end
