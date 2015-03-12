# == Schema Information
#
# Table name: area_editor_assignments
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  submission_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class AreaEditorAssignment < ActiveRecord::Base
  belongs_to :area_editor, class_name: 'User', foreign_key: 'user_id'
  belongs_to :submission
  after_save :handle_save
  before_destroy :stash_variables
  after_destroy :handle_destroy

  private

    def handle_save
      if user_id_changed?
        unless user_id_was  # new assignment
          NotificationMailer.notify_ae_new_assignment(self.submission).save_and_deliver
        else  # old assignment changing hands              
          old_ae = User.find(user_id_was)
          NotificationMailer.notify_ae_assignment_canceled(self.submission, old_ae).save_and_deliver
          self.submission.reload # necessary to avoid overwriting submission.original
          self.submission.set_auth_token  # invalidate old auth_token
          self.submission.save
          NotificationMailer.notify_ae_new_assignment(self.submission.reload).save_and_deliver
        end
      end
    end
    
    def stash_variables
      @submission = self.submission
      @area_editor = self.area_editor
    end
      
    def handle_destroy
      @submission.set_auth_token  # invalidate old auth_token
      @submission.save
      NotificationMailer.notify_ae_assignment_canceled(self.submission, @area_editor).save_and_deliver if user_id_was
    end
    
end
