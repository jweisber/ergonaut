module SentEmailsHelper
  def linkify_email_list(list)
    addresses = list.split(', ')
    addresses.map! { |a| mail_to(a) }
    addresses.join(', ').html_safe
  end
end
