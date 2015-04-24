module Jabber
  module MUC
    module HipChat
      class ReceivedMessage < ReceivedStanza
        alias_method :recipient_id, :user_id

        def topic
          @stanza.subject.to_s
        end

        def body
          @stanza.body.to_s
        end

        ## Invite

        def topic?
          @stanza.children.first.name == "subject"
        end

        def invite?
          !@stanza.x.nil? &&
            @stanza.x.kind_of?(XMUCUser) &&
            @stanza.x.first.kind_of?(XMUCUserInvite)
        end

        def room_name
          @stanza.children.last.first_element_text('name')
        end
      end
    end
  end
end
