module Jabber
  module MUC
    module HipChat
      class ReceivedPresence < ReceivedStanza
        def initialize stanza, chat_host
          super stanza
          @is_lobby = chat_host == host
        end

        def lobby?
          @is_lobby
        end

        def type
          super || @stanza.show || :available
        end

        ## Room presence

        def role
          item.affiliation if item
        end

        private

        def host
          @stanza.from.domain if @stanza.from
        end
      end
    end
  end
end
