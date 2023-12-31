class BatchesController < ApplicationController
  before_action :authenticate_user!, except: [:new, :show, :search]
  before_action :set_batch, only: [:show, :edit, :update, :destroy, :prepare_tx, :download_pdf, :generate_pdf,:generate_directory_pdf,:download_directory_pdf, :search]
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  
  def search
    @issuer = @batch.issuer
    @first_block = @batch.first_block
    
  end
  
  def generate_pdf
    # generate pdf file in tmp/diploma_batch_+ @batch.id.to_s.pdf"
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
    	page_count = count/25 # get remainder with count % 20
      
      @issuer = @batch.issuer
      school_name = @issuer.name
      batch_title = @batch.title
      school_address = @batch.payment_address
      root_file_name = "diploma_batch_"+ @batch.id.to_s
      logopath = "#{::Rails.root.to_s}/public/" + @issuer.logo_path # warning: Prawn does NOT handle interlace png image
     
       Prawn::Document.generate("tmp/#{root_file_name}.pdf") do

          image logopath, :width => 275, :height => 85

          move_down 20

          font "Helvetica"
          font_size 18
          text_box "#{school_name}"+", #{batch_title}"+ "\n" + "#{count} diplomas", :align => :right          
          font_size 12
          
          j = 0
          p = 0
          
          if page_count > 0
            
            page_count.times do
              
              k = p*25
              
              table_header = [ ["Diploma SHA256 Digest"] ]
              table(table_header, 
                :column_widths => [400])
              font_size 10

            while k < (p+1)*25
              
                batchinfo = [[rows[k][0]]]
                table(batchinfo, 
                  :column_widths => [400], 
                  :row_colors => ["d2e3ed", "FFFFFF"],
                  :cell_style => { :align => :right })
                      
                k += 1
              end
              p += 1
              start_new_page
            end
            
            k = page_count*25
            table_header = [ ["Diploma SHA256 Digest"] ]
            table(table_header, 
                :column_widths => [400])
            font_size 10

          while k < (page_count*25 + (count % 25))
            
              batchinfo = [[rows[k][0]]]

              table(batchinfo, 
                :column_widths => [400], 
                :row_colors => ["d2e3ed", "FFFFFF"],
                :cell_style => { :align => :right })
                    
              k += 1
            end
            
          else
            k = 0
            table_header = [ ["Diploma SHA256 Digest"] ]
            table(table_header, 
                :column_widths => [400])
            font_size 10
            while k < compteur
              
                batchinfo = [[rows[k][0]]]
                table(batchinfo, 
                  :column_widths => [400], 
                  :row_colors => ["d2e3ed", "FFFFFF"],
                  :cell_style => { :align => :right })
                      
                k += 1
              end
          end
          
          font_size 10
          move_down 20
          text "School Address: " + " #{school_address}", :align => :left
          move_down 10
          text "School & Year: " + " #{school_name}" + ", #{batch_title}", :align => :left
          
          string = "page <page> of <total>"

          options = { :at => [bounds.right - 150, 0],
                      :width => 150,
                      :align => :right,
                      :page_filter => (1..7),
                      # :color => "007700",
                      :start_count_at => 1 }
          number_pages string, options
          options [:page_filter] = lambda { |pg| pg > 7 }
          options[:start_count_at] = 8
          number_pages string, options
        
        end # of Prawn::Document.generate
       redirect_to @batch, notice: 'PDF File was successfully created.'
     end # of generate_pdf method
     
     
     def generate_directory_pdf
       # generate pdf file in tmp/class_directory_+ @batch.id.to_s.pdf"
        @deeds = @batch.deeds.where("category = ?", Deed.categories['diploma'])
        rows = []
        compteur = 0
        @deeds.each do |deed|
          rows << [deed.description, deed.upload]
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
       	page_count = count/25 # get remainder with count % 20
      
         @issuer = @batch.issuer
         school_name = @issuer.name
         batch_title = @batch.title
         school_address = @batch.payment_address
         root_file_name = "class_directory_"+ @batch.id.to_s
         logopath = "#{::Rails.root.to_s}/public/" + @issuer.logo_path # warning: Prawn does NOT handle interlace png image
     
          Prawn::Document.generate("tmp/#{root_file_name}.pdf") do

             image logopath, :width => 275, :height => 85

             move_down 20

             font "Helvetica"
             font_size 18
             text_box "#{school_name}"+", #{batch_title}"+ "\n" + "#{count} diplomas", :align => :right          
             font_size 12
          
             j = 0
             p = 0
          
             if page_count > 0
            
               page_count.times do
              
                 k = p*25
                 cell_1 = make_cell(:content => "Name ")
                 cell_2 = make_cell(:content => "Diploma SHA256 Digest ")
                 table_header = [[ cell_1,cell_2]]
                 table(table_header, :column_widths => [140,400])
                 font_size 10

               while k < (p+1)*25
          
                 name = rows[k][0]
                 file_digest = rows[k][1]
                 data = [ [name,file_digest] ]
                 table(data, 
                     :column_widths => [140,400], 
                     :row_colors => ["d2e3ed", "FFFFFF"],
                     :cell_style => { :align => :right })
                      
                   k += 1
                 end
                 p += 1
                 start_new_page
               end
            
               k = page_count*25
               cell_1 = make_cell(:content => "Name ")
               cell_2 = make_cell(:content => "Diploma SHA256 Digest ")
               table_header = [[ cell_1,cell_2]]
               table(table_header, :column_widths => [140,400])
               font_size 10

             while k < (page_count*25 + (count % 25))
            
               name = rows[k][0]
               file_digest = rows[k][1]
               data = [ [name,file_digest] ]
               table(data, 
                   :column_widths => [140,400], 
                   :row_colors => ["d2e3ed", "FFFFFF"],
                   :cell_style => { :align => :right })
                    
                 k += 1
               end
            
             else
               k = 0
               cell_1 = make_cell(:content => "Name ")
               cell_2 = make_cell(:content => "Diploma SHA256 Digest ")
               table_header = [[ cell_1,cell_2]]
               table(table_header, :column_widths => [140,400])
               font_size 10
               while k < compteur
              
                 name = rows[k][0]
                 file_digest = rows[k][1]
                 data = [ [name,file_digest] ]
                 table(data, 
                     :column_widths => [140,400], 
                     :row_colors => ["d2e3ed", "FFFFFF"],
                     :cell_style => { :align => :right })
                      
                   k += 1
                 end
             end
          
             font_size 10
             move_down 20
             text "School Address: " + " #{school_address}", :align => :left
             move_down 10
             text "School & Year: " + " #{school_name}" + ", #{batch_title}", :align => :left
          
             string = "page <page> of <total>"

             options = { :at => [bounds.right - 150, 0],
                         :width => 150,
                         :align => :right,
                         :page_filter => (1..7),
                         # :color => "007700",
                         :start_count_at => 1 }
             number_pages string, options
             options [:page_filter] = lambda { |pg| pg > 7 }
             options[:start_count_at] = 8
             number_pages string, options
        
           end # of Prawn::Document.generate
          redirect_to @batch, notice: 'Class Directory PDF File was successfully created.'
        end # of generate_directory_pdf method
     
     
  def download_pdf
    root_file_name = "diploma_batch_"+ @batch.id.to_s
    send_file "#{Rails.root.join('tmp').to_s}/#{root_file_name}.pdf"
  end
  
  def download_directory_pdf
    file_name = "class_directory_"+ @batch.id.to_s
    send_file "#{Rails.root.join('tmp').to_s}/#{file_name}.pdf"
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
      redirect_to @batch, notice: "Raw signed batch tx was successfully created."
    end
  end
  
  def index
    @batches = Batch.all
    @batches.each do |batch|
      unless batch.issuer_id
        @batches.delete(batch)
      end
    end
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
    @first_block = first_block(@batch.payment_address)
    @deeds = @batch.deeds.where("category = ?", Deed.categories['diploma'])
    @deeds = @deeds.sort_by { |deed| deed.created_at }
    values = Hash.new
    @deeds.each do |deed|
      values["#{deed.id}"] = deed.description.split(" ")[1]
    end
    puts values
    
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
