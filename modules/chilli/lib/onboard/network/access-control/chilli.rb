autoload :IPAddr, 'onboard/extensions/ipaddr'

class OnBoard

  module System
    autoload :Process, 'onboard/system/process'
  end

  module Network
    module AccessControl
      class Chilli
        DEFAULT_CONF_FILE = '/etc/chilli.conf'

        def self.getAll
          ary = []
          `pidof chilli`.split.each do |pid|
            ary << new(
              :process => OnBoard::System::Process.new(pid)
            )
          end
          return ary
        end

        def self.parse_conffile(filename)
          h = {}
          File.foreach(filename) do |line|
            line.sub! /#.*$/, ''
            if line =~ /(\S+)\s+(.*)\s*$/  
              opt, arg = $1, $2
              arg.strip!
              if arg =~ /^"(.*)"$/ # remove double quote
                arg = $1
              end
              if arg == "" # NOTE: necessary ?
                arg = true
              end
            elsif line =~ /^\s*(\S+)\s*$/
              opt, arg = $1, true
            else
              next
            end
            h[opt] = arg unless opt =~ /secret/ # do no export passwords
          end
          return h
        end

        attr_reader :data, :conf, :managed
        
        def initialize(h)
          @process = h[:process]
          @conffile = conffile()
          @managed = managed?
          @conf = self.class.parse_conffile(@conffile)
        end

        # true if the config file is a subdirectory of 
        # OnBoard::Network::AccessControl::Chilli::CONFDIR
        def managed?
          return true if @conffile[CONFDIR] 
          return false
        end

        def conffile
          # cache...
          if instance_variable_defined? :@conffile and @conffile
            return @conffile
          end
          cmdline = @process.cmdline # Array, like in ARGV ...
          index = cmdline.index('--conf') 
          unless index # --conf option not found
            @conffile = DEFAULT_CONF_FILE
            return @conffile 
          end
          argument = cmdline[index + 1] 
          if argument =~ /^\-/
            fail "bad chilli command line: #{cmdline.inspect}" 
          end
          if argument =~ /^\// # absolute path
            @conffile = argument
          else
            @conffile = File.join @process.cwd, argument
          end
          return @conffile
        end

        def dhcp_range
          ip_net = IPAddr.new @conf['net']
          ip_uamlisten = IPAddr.new @conf['uamlisten']
          if conf['dhcpstart']
            ip_dhcpstart = ip_net + @conf['dhcpstart']
          else
            ip_dhcpstart = ip_net + 1
            if ip_dhcpstart == ip_uamlisten
              ip_dhcpstart += 1
            end
          end
          if conf['dhcpend']
            ip_dhcpend = ip_net + @conf['dhcpend'] 
          else
            ip_dhcpend = ip_net.to_range.last - 1
          end
          return (ip_dhcpstart..ip_dhcpend) 
        end

        def data
          {
            'process'   => {
              'pid'       => @process.pid,
              'cmdline'   => @process.cmdline,
              'cwd'       => @process.cwd
            },
            'conffile'  => conffile(),
            'conf'      => @conf,
            'dhcprange' => {
              'start'     => dhcp_range.first.to_s,
              'end'       => dhcp_range.last.to_s
            }
          }
        end

      end
    end
  end
end

