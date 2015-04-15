module Jabber
  module MUC
    class SlackClient
      attr_reader :my_jid

      def initialize jid, conference_host = nil
        @my_jid     = JID.new(jid)

        @presence   = HipChat::Presence.new(my_jid)
        @message    = HipChat::Message.new(my_jid)

        @conference_host = conference_host
      end

      def join jid, fetch_history = false
        Jabber::debuglog "Joining #{jid}"
        @presence.get_join(jid, fetch_history).send_to(stream)
      end

      def exit jid, reason = nil
        Jabber::debuglog "Exiting #{jid}"
        @presence.get_leave(jid, reason).send_to(stream)
      end

      def set_presence status = nil, type = :available, room_jid = nil
        Jabber::debuglog "Setting presence to #{type} in #{room_jid} with #{status}"
        @presence.get_status(type, room_jid, status).send_to(stream)
      end

      def keep_alive password
        if stream.is_disconnected?
          Jabber::debuglog "Stream disconnected. Connecting again..."
          connect(password)
        end
      end

      def name
        my_jid.resource
      end

      def name= resource
        my_jid.resource = resource
      end

      %w(lobby_presence room_presence room_message private_message invite).each do |callback_name|
        define_method("on_#{callback_name}") do |prio = 0, ref = nil, &block|
          callbacks[callback_name.to_sym].add(prio, ref) do |*args|
            block.call(*args)
          end
        end
      end

      def kick(recipients, room_jid)
        HipChat::KickMessage.new(my_jid).make(room_jid, recipients).send_to(stream)
      end

      def invite(recipients, room_jid)
        @message.get_invite(room_jid, recipients).send_to(stream)
      end

      def send_message(type, jid, text, subject = nil)
        @message.get_text(type, jid, text, subject).send_to(stream)
      end

      def connect password
        stream.connect
        Jabber::debuglog "Connected to stream"
        stream.auth(password)
        Jabber::debuglog "Authenticated"
        true
      end

      def activate_callbacks
        stream.add_stanza_callback(0, self) do |stanza|
          handle_stanza(HipChat::ReceivedStanza.new(stanza, chat_host))
        end
        Jabber::debuglog "Callbacks activated"
      end

      def get_rooms
        HipChat::RoomData.get_rooms_data(stream, conference_host)
      end

      def get_users
        HipChat::UserData.get_users_data(stream)
      end

      def get_user_details user_jid
        HipChat::VCard.get_details(stream, user_jid)
      end

      def deactivate_callbacks
        stream.delete_stanza_callback(self)
        Jabber::debuglog "Callbacks deactivated"
      end

      private

      def chat_host
        my_jid.domain
      end

      def conference_host
        @conference_host ||= begin
          MUCBrowser.new(stream).muc_rooms(chat_host).keys.first
        end
      end

      def stream
        @stream ||= Client.new(my_jid.strip) # TODO: Error Handling
      end

      def callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = CallbackList.new }
      end

      def handle_stanza(stanza)
        case stanza.name
        when 'message'
          handle_message(stanza)
        when 'presence'
          handle_presence(stanza)
        end
      end

      def handle_presence(presence)
        if presence.lobby?
          callbacks[:lobby_presence].process(presence.from_jid, presence.type)
        else
          callbacks[:room_presence].process(
            presence.from_jid,
            presence.user_name,
            presence.type,
            presence.role,
          )
        end
      end

      def handle_message(message)
        case message.type
        when :chat
          handle_private_message(message)
        when :groupchat
          handle_private_message(message)
        when :error
          handle_error(message)
        else
          handle_invite(message)
        end
      end

      def handle_invite(message)
        callbacks[:invite].process(
          message.from_jid,
          message.user_name,
          message.room_name,
          message.topic,
        )
      end

      def handle_private_message(message)
        callbacks[:private_message].process(
          message.from_jid,
          message.body,
        )
      end

      def handle_group_message(message)
        callbacks[:room_message].process(
          message.from_jid,
          message.user_name,
          message.body,
          message.topic,
        )
      end

      def handle_error(message)
        false
      end
    end
  end
end
