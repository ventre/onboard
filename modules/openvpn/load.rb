class OnBoard
  module Network
    module OpenVPN
      ROOTDIR = File.dirname(__FILE__)
      $LOAD_PATH.unshift  ROOTDIR + '/lib'
      OnBoard.find_n_load ROOTDIR + '/etc/menu'
      OnBoard.find_n_load ROOTDIR + '/controller'
    end
  end
end


