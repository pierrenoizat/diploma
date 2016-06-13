class UpdateMpkService
  def call
    @issuers = Issuer.all
    @issuers.each do |issuer|
        # pick issuer-specific (school) mpk
         
         if issuer.msk == Rails.application.secrets.msk_esilv
           mpk = Rails.application.secrets.mpk_esilv
         else
           mpk = Rails.application.secrets.mpk
         end

         issuer.update(:mpk => mpk)
         
      end
  end
end
