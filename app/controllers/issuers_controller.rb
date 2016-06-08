class IssuersController < ApplicationController
  before_action :set_issuer, only: [:show, :edit, :update, :destroy]
  before_action :current_user_admin?, :except => [:show, :school_list]
  
  include Bitcoin::Builder

  # GET /issuers
  # GET /issuers.json
  def index
    @issuers = Issuer.all
  end
  
  def school_list
   @issuers = []
   @issuer = Issuer.find_by_name("ESILV 2014")
   @issuers << @issuer
    
  end

  # GET /issuers/1
  # GET /issuers/1.json
  def show
    @master = MoneyTree::Master.from_bip32(@issuer.mpk)
    @payment_node = @master.node_for_path "M/3/#{@issuer.id}" # capital M for"public-key only" node, we could be using m for full "secret-key" node
    @payment_address = @payment_node.to_address # TODO publish this address next to school name and class (year)
  end

  # GET /issuers/new
  def new
    @issuer = Issuer.new
  end

  # GET /issuers/1/edit
  def edit
  end

  # POST /issuers
  # POST /issuers.json
  def create
    @issuer = Issuer.new(issuer_params)

    respond_to do |format|
      if @issuer.save
        format.html { redirect_to @issuer, notice: 'Issuer was successfully created.' }
        format.json { render :show, status: :created, location: @issuer }
      else
        format.html { render :new }
        format.json { render json: @issuer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /issuers/1
  # PATCH/PUT /issuers/1.json
  def update
    respond_to do |format|
      if @issuer.update(issuer_params)
        format.html { redirect_to @issuer, notice: 'Issuer was successfully updated.' }
        format.json { render :show, status: :ok, location: @issuer }
      else
        format.html { render :edit }
        format.json { render json: @issuer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issuers/1
  # DELETE /issuers/1.json
  def destroy
    @issuer.destroy
    respond_to do |format|
      format.html { redirect_to issuers_url, notice: 'Issuer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_issuer
      @issuer = Issuer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def issuer_params
      params.require(:issuer).permit(:category, :name, :batch, :mpk, deeds_attributes: [:issuer_id])
    end
end
