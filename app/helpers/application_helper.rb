module ApplicationHelper

  def tx_link(string)
    "https://live.blockcypher.com/btc/tx/#{string}/"
  end
  
  def public_link(string)
    $ROOT_URL + "/deeds/#{string}/public_display"
  end

end