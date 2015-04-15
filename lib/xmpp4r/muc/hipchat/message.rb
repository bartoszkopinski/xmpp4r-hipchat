module Jabber
  module MUC
    module HipChat
      class Message < Jabber::Message
        def initialize my_jid
          super()
          @my_jid    = my_jid
          self.from  = my_jid
          @semaphore = Mutex.new
        end

        def get_text type, jid, text, subject = nil
          self.dup.tap do |d|
            d.body    = text.to_s
            d.to      = JID.new(jid)
            d.type    = type
            d.subject = subject if subject
          end
        end

        def get_invite room_jid, recipient_jids
          self.dup.tap do |d|
            d.to = JID.new(room_jid)

            recipient_jids.each do |recipient_jid|
              d.add_recipient(recipient_jid)
            end
          end
        end

        def add_recipient jid
          xmuc_user.add(XMUCUserInvite.new(jid))
        end

        def send_to stream, &block
          Thread.new do
            @semaphore.synchronize {
              stream.send(self, &block)
              sleep(0.2)
            }
          end
        end

        private

        def xmuc_user
          @xmuc_user ||= add(XMUCUser.new)
        end
      end
    end
  end
end
