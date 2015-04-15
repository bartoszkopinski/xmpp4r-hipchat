module Jabber
  module MUC
    module HipChat
      class ReceivedPresence
        def initialize presence, chat_host
          @presence = presence
          @is_lobby = chat_host == host
        end

        def lobby?
          @is_lobby
        end

        def from_jid
          @presence.from.strip.to_s
        end

        def user_name
          @presence.from.resource.to_s
        end

        def role
          @presence.x.items.first.role
        end

        def host
          @presence.from.domain
        end

        def type
          @presence.type || :available
        end
      end
    end
  end
end
