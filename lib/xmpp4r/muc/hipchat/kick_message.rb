module Jabber
  module MUC
    module HipChat
      class KickMessage < Iq
        def initialize my_jid
          super(:set)
          self.from = my_jid
          self.add(IqQueryMUCAdmin.new)
        end

        def make room_jid, recipients
          self.to = room_jid

          recipients.each do |recipient|
            add_recipient(recipient)
          end
        end

        def add_recipient nick
          item      = IqQueryMUCAdminItem.new
          item.nick = nick
          item.role = :none
          self.query.add(item)
        end

        def send_to(stream)
          stream.send_with_id(self)
        end
      end
    end
  end
end
