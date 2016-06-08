class UpdateMpkService
  def call
    @issuers = Issuer.all
    @issuers.each do |issuer|
        # pick issuer-specific (school) mpk
         mpk = case issuer.name
         when "ESILV 2014"
          Rails.application.secrets.mpk_esilv
         when "TEST SCHOOL"
          Rails.application.secrets.mpk_esilv
         when "TEST"
          Rails.application.secrets.mpk_esilv
         when "CDI"
          Rails.application.secrets.mpk_esilv
         else
          Rails.application.secrets.mpk
         end
         # user.update {name: "Rob", age: 12}
         issuer.update(:mpk => mpk)
         
      end
  end
end
