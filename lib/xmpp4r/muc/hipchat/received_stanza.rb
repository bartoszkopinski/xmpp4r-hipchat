module Jabber
  module MUC
    module HipChat
      class ReceivedStanza
        def initialize stanza, chat_host
          @stanza  = stanza
          @is_lobby = chat_host == host
        end

        def invite?
          !@stanza.x.nil? &&
            @stanza.x.kind_of?(XMUCUser) &&
            @stanza.x.first.kind_of?(XMUCUserInvite)
        end

        def name
          @stanza.name
        end

        def lobby?
          @is_lobby
        end

        def role
          @stanza.x.items.first.role
        end

        def host
          @stanza.from.domain
        end

        def type
          @stanza.type || :available
        end

        def user_name
          @stanza.from.resource.to_s
        end

        def from_jid
          @stanza.from.strip.to_s
        end

        def topic
          if invite?
            @stanza.children.last.first_element_text('topic')
          else
            @stanza.subject.to_s
          end
        end

        def room_name
          @stanza.children.last.first_element_text('name')
        end

        def body
          @stanza.body.to_s
        end
      end
    end
  end
end
