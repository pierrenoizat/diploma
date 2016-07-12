FactoryGirl.define do
factory :issuer do
  mpk "xpub661MyMwAqRbcG55r8ZsYPqywS8iK4endA313Q3xbSrn7gaJAjNM6yyviKLtfcp8KGLWRyPjh3utXYG6sqixndA6sbY6N4VEzPnJmR6ShMWG"
  name  "MySchool"
  id '101'

  factory :issuer_with_batch do
    after(:create) do |issuer|
      create(:batch, issuer: issuer)
    end
  end
end

factory :batch do
  title '2008'
  address '1KgM2Ffk3ENkJzGjQD2vf1Jxv4PJnkt5Em'
  id '88'
end
end