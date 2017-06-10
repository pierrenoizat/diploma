module Utxo
  extend ActiveSupport::Concern
  
  def address_utxo_count(address)

    # returns count ( < $STUDENTS_COUNT) of utxos available to fund OP_RETURN transactions from single address (school class diplomas).
    # TODO publish this address next to school name and class (year)
    string = $BLOCKR_ADDRESS_UNSPENT_URL  + address
    puts string
    @agent = Mechanize.new

    begin
     page = @agent.get string
    rescue Exception => e
     page = e.page
    end

    data = page.body
    result = JSON.parse(data)
    if result['status'].include?("error")
     result['status']
     return 0 # most likely, too many request
    else
     if result['data']['unspent']
      return result['data']['unspent'].count
     else
      return 0
     end
    end
   
  end
  
  
  def balance(address)
    # returns balance of address in satoshis
    string = $BLOCKR_ADDRESS_BALANCE_URL + address + "?confirmations=0"
    @agent = Mechanize.new
    begin
      page = @agent.get string
    rescue Exception => e
      page = e.page
    end
    data = page.body
    result = JSON.parse(data)
    if result['status'].include?("error")
      puts result['status']
      return 0 # most likely, too many request
    else 
      return (result['data']['balance'].to_f)*100000000
    end
  end


end