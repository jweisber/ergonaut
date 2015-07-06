# == Schema Information
#
# Table name: sent_emails
#
#  id                    :integer          not null, primary key
#  submission_id         :integer
#  referee_assignment_id :integer
#  action                :string(255)
#  subject               :string(255)
#  to                    :string(255)
#  cc                    :string(255)
#  body                  :text(65535)
#  attachments           :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null


class SentEmail < ActiveRecord::Base
  belongs_to :submission
  belongs_to :referee_assignment
  validates :action, :subject, :to, :body, presence: true, length: { minimum: 1 }
  
  def self.create_from_message(message)
    SentEmail.create(
      submission: message.submission,
      referee_assignment: message.referee_assignment,
      action: message.action,
      subject: message.subject,
      to: message.to.join(', '),
      cc: message.cc.join(', '),
      body: message.body_text,
      attachments: message.attachments.map{ |a| a.filename }.join(', ')
    )
  end
  
  def date_sent_pretty
    self.created_at.strftime("%b. %-d, %Y")
  end

  def datetime_sent_pretty
    self.created_at.strftime("%b. %-d, %Y @ %l:%M %p")
  end
end
