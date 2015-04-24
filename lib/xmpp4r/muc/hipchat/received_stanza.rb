module Jabber
  module MUC
    module HipChat
      class ReceivedStanza
        def initialize stanza
          @stanza = stanza
        end

        # Presence Types: :available, :unavailable, ...
        # Message Types: :chat, :groupchat, :error, ...
        def type
          @stanza.type
        end

        # User ID is available in presences and private messages
        def user_id
          item.jid.node if item
        end

        def sender_id
          @stanza.from.node
        end
        alias_method :room_id, :sender_id

        # Used in room message or presence
        def sender_name
          @stanza.from.resource
        end

        private

        def item
          @item ||= begin
            if @stanza.x.respond_to?(:items)
              @stanza.x.items.first
            end
          end
        end
      end
    end
  end
end
