class BatchesController < ApplicationController
  before_action :authenticate_user!, except: [:new, :show]
  before_action :set_batch, only: [:show, :edit, :update, :destroy, :prepare_tx, :download_pdf, :generate_pdf]
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  
  
  def generate_pdf

     @deeds = @batch.deeds
     rows = []
     compteur = 0
     @deeds.each do |deed|
       rows << [deed.upload]
       compteur += 1
       end
     
     @current_time = Time.now

      temps = case I18n.locale.to_s
    		when 'en' then @current_time.strftime('%D')
    		when 'fr' then @current_time.strftime("%d %m %Y")
    		else @current_time.strftime("%B %d, %Y")
    		end
    	temps = " #{temps} - " + "#{@current_time.strftime("%H:%M")}"

    	count = @deeds.count
      
      @issuer = @batch.issuer
      school_name = @issuer.name
      batch_title = @batch.title
      school_address = @batch.payment_address
      root_file_name = "diploma_batch_"+ @batch.id.to_s
     
       # Prawn::Document.new do
       Prawn::Document.generate("tmp/#{root_file_name}.pdf") do
         
         logopath = $PRINT_PDF_LOGO_PATH # warning: Prawn does NOT handle interlace png image
          image logopath, :width => 128, :height => 57

          move_down 50

          font "Helvetica"
          font_size 18
          text_box "#{school_name}"+", #{batch_title}", :align => :right          

          move_down 20

          font_size 10
          # text "#{school_name}", :align => :left
          text "#{count} diplomas", :align => :left
          move_down 20
          font_size 12
          move_down 20

          table_header = [ ["Diploma Digest"] ]

            table(table_header, 
              :column_widths => [380])
              #:position => :right )
          font_size 10
          j = 0
          while j < compteur
        
            batchinfo = [[rows[j][0]]]

            table(batchinfo, 
                  :column_widths => [380], 
                  :row_colors => ["d2e3ed", "FFFFFF"],
                  :cell_style => { :align => :right })
          j += 1
          end
          font_size 10
          move_down 20
          text "School Address: " + " #{school_address}", :align => :left
          move_down 10
          text "School & Year: " + " #{school_name}" + ", #{batch_title}", :align => :left
        
        end # of Prawn::Document.generate
       redirect_to @batch, notice: 'PDF File was successfully created.'
     end # of generate_pdf method
     
     
     def download_pdf
       root_file_name = "diploma_batch_"+ @batch.id.to_s
       send_file "#{Rails.root.join('tmp').to_s}/#{root_file_name}.pdf"
     end
  
  def prepare_tx
    if address_utxo_count(@batch.payment_address) == 0
      address_balance = balance($PAYMENT_ADDRESS)
      if address_balance < 2*$NETWORK_FEE
        puts address_balance
        puts "Network fee is " + $NETWORK_FEE.to_s + " Satoshis"
        puts "We need to fund " + $PAYMENT_ADDRESS + " with " + (2*$NETWORK_FEE).to_s + " Satoshis"
      else
        @batch.batch_init_tx
        puts address_balance
        puts "Everything OK with " + $PAYMENT_ADDRESS
      end
      redirect_to @batch, notice: 'No utxo available yet. Try again later'
    else
      @batch.root_hash = @batch.root_file_hash
      @batch.save
      @batch.batch_authentification_tx
      redirect_to @batch, notice: 'Raw signed batch tx was successfully created.'
    end
  end
  
  def index
    @batches = Batch.all
  end
  
  def new
    @batch = Batch.new
    @issuers = Issuer.all
  end
  
  def create

    @batch = Batch.new(batch_params)
    
    require 'digest'
    require 'openssl'

    respond_to do |format|
      if @batch.save
        
        format.html { redirect_to @batch, notice: 'batch was successfully created.' }
        format.json { render :show, status: :created, location: @batch }
      else
        flash[:error] = @batch.errors[:base]
        format.html { render :new, notice: 'batch could not be saved: user not authorized by issuer.' }
        format.json { render json: @batch.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def show
    @issuer = @batch.issuer
  end
  
  def edit
    @issuers = Issuer.all
  end
  
  def update
    respond_to do |format|
      if @batch.update(batch_params.except(:user_id))
        format.html { redirect_to @batch, notice: 'batch was successfully updated.' }
        format.json { render :show, status: :ok, location: @batch }
      else
        format.html { render :edit }
        format.json { render json: @batch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /batchs/1
  # DELETE /batchs/1.json
  def destroy
    
    @batch.delete
    respond_to do |format|
      format.html { redirect_to current_user, notice: 'Batch was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  private

    def set_batch
      @batch = Batch.find_by_id(params[:id])
    end

    def batch_params
      params.require(:batch).permit(:issuer_id, :title)
    end
  
end