module Jabber
  module MUC
    module HipChat
      class ReceivedMessage
        def initialize message
          @message = message
        end

        def invite?
          !@message.x.nil? &&
            @message.x.kind_of?(XMUCUser) &&
            @message.x.first.kind_of?(XMUCUserInvite)
        end

        %w(chat groupchat error).each do |type|
          define_method("#{type}?") do
            @message.type == type.to_sym
          end
        end

        def user_name
          @message.from.resource.to_s
        end

        def from_jid
          @message.from.strip.to_s
        end

        def topic
          if invite?
            @message.children.last.first_element_text('topic')
          else
            @message.subject.to_s
          end
        end

        def room_name
          @message.children.last.first_element_text('name')
        end

        def body
          @message.body.to_s
        end
      end
    end
  end
end
