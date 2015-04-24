module Jabber
  module MUC
    module HipChat
      class Presence < Jabber::Presence
        def initialize my_jid
          super(:chat)
          @my_jid   = my_jid
          self.from = my_jid
        end

        def get_leave jid, reason = nil
          get_status(:unavailable, room_jid(jid), reason)
        end

        def get_join jid, fetch_history = false
          get_status(:available, room_jid(jid)) # TODO: Handle all join responses
        end

        def get_status type, to = nil, status = nil, fetch_history = false
          self.dup.tap do |d|
            d.set_status(status)
            d.set_type(type)
            d.no_history! unless fetch_history
            d.to = to
          end
        end

        def no_history!
          element = REXML::Element.new('history').tap do |h|
            h.add_attribute('maxstanzas', '0')
          end

          xmuc = XMUC.new
          xmuc.add_element(element)
          self.add(xmuc)
        end

        def send_to stream, &block
          stream.send(self, &block)
        end

        private

        def room_jid jid
          JID.new(jid).tap do |j|
            j.resource = @my_jid.resource
          end
        end
      end
    end
  end
end
