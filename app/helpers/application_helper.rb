module ApplicationHelper

  def tx_link(string)
    
   # "https://live.blockcypher.com/btc/tx/#{string}/"
    
    "https://www.blocktrail.com/BTC/tx/#{string}/"
  end
  
  def public_link(string)
    $ROOT_URL + "/deeds/#{string}/public_display"
  end
  
  def first_block_old(address)
    # returns first block (oldest) where address can be found in a transaction input
    # fetch all txs for address
    # string = "http://btc.blockr.io/api/v1/address/txs/" + address
    string = "https://blockchain.info/address/" + address + "?format=json"
    
    @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     n = result['n_tx']
     block = 840000
     if n > 0 # address was used
       
       k = 0

       while k < n
        result['txs'].each do |tx|
          tx['inputs'].each do |input|
            if input["prev_out"]["addr"] == address
              block = [ block, tx["block_height"]].min
            end
          end
        end
        
        k += 1
       end # of while loop

       block
     else
       puts "virgin address: " + address
       return nil
     end
    
  end
  
  def first_block(address)
    # returns first block (oldest) where address can be found in a transaction input
    # fetch all txs for address
    string = "http://btc.blockr.io/api/v1/address/txs/" + address
    # string = "https://blockchain.info/address/" + address + "?format=json"
    
    @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     n = result["data"]["nb_txs"]
     block = 840000
     if n > 0 # address was used

        result["data"]["txs"].each do |tx|
          tx_hash = tx["tx"]
          if  input?(address, tx_hash)
            block = [ block, block_height(tx_hash)].min
            puts block
          end
        end

       block
     else
       puts "virgin address: " + address
       return nil
     end
    
  end # of first_block helper
  
  def block_height(tx_hash)
    
    string = "http://btc.blockr.io/api/v1/tx/info/" + tx_hash
    @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     result["data"]["block"]
     
  end # of block_height helper
  
  def input?(address, tx_hash)
    # returns true if address is an input of tx
    boole = false
    string = "http://btc.blockr.io/api/v1/tx/info/" + tx_hash
    @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     result["data"]["vins"].each do |vin|
       if (vin["address"] == address)
         boole = true
       end
     end
    boole
  end

end