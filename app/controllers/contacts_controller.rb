class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(params[:contact])
    @contact.request = request
    boolean = false
    
    boolean = EmailValidator.valid?(@contact.email) # boolean
    
    if (Notifier.form_received(@contact).deliver_now and boolean)
      flash.now[:notice] = 'Thanks for your message!'
      # redirect_to root_url, notice: 'Thanks for your message!'
    else
      @contact.email = ""
      # render :new
      redirect_to page_path('contact'), alert: 'There was a problem with the email address you entered.'
    end
    
  end
end
