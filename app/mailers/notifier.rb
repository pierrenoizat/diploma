class Notifier < ActionMailer::Base
  default :from => 'diploma'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.notifier.order_received.subject
  
  include ActionView::Helpers::TextHelper
  
  def depleted
    mail :to => "noizat@hotmail.com", :from => "diploma.report", :subject => 'Diploma.report Notification'
  end
  
end
