module Jabber
  module MUC
    class HipchatClient
      attr_reader :my_jid

      def initialize jid, conference_host = nil
        @my_jid     = JID.new(jid)

        @presence   = HipChat::Presence.new(my_jid)
        @message    = HipChat::Message.new(my_jid)

        @conference_host = conference_host
      end

      def name
        my_jid.resource
      end

      def name= resource
        my_jid.resource = resource
      end

      ## Actions

      def join room_id, fetch_history = false
        jid = JID.new(room_id, conference_host)
        Jabber::debuglog "Joining #{jid}"
        @presence.get_join(jid, fetch_history).send_to(stream)
      end

      def exit room_id, reason = nil
        jid = JID.new(room_id, conference_host)
        Jabber::debuglog "Exiting #{jid}"
        @presence.get_leave(jid, reason).send_to(stream)
      end

      def set_presence status = nil, type = :available, room_id = nil
        room_jid = room_id ? JID.new(room_id, conference_host) : nil
        Jabber::debuglog "Setting presence to #{type} in #{room_jid} with #{status}"
        @presence.get_status(type, room_jid, status).send_to(stream)
      end

      def kick user_ids, room_id
        room_jid = JID.new(room_id, conference_host)
        user_jids = user_ids.map{ |id| JID.new(id, chat_host) }
        Jabber::debuglog "Kicking #{user_jids} from #{room_jid}"
        HipChat::KickMessage.new(my_jid).make(room_jid, user_jids).send_to(stream)
      end

      def invite user_ids, room_id
        room_jid = JID.new(room_id, conference_host)
        user_jids = user_ids.map{ |id| JID.new(id, chat_host) }
        Jabber::debuglog "Inviting #{user_jids} to #{room_jid}"
        @message.get_invite(room_jid, user_jids).send_to(stream)
      end

      def send_message type, recipient_id, text, subject = nil
        jid = JID.new(recipient_id, type == :chat ? chat_host : conference_host)
        @message.get_text(type, jid, text, subject).send_to(stream)
      end

      ## Fetching

      def get_rooms
        HipChat::RoomData.get_rooms_data(stream, conference_host)
      end

      def get_users
        HipChat::UserData.get_users_data(stream)
      end

      def get_user_details user_id
        HipChat::VCard.get_details(stream, user_id)
      end

      ## Connection

      def connect password
        stream.connect
        Jabber::debuglog "Connected to stream"
        stream.auth(password)
        Jabber::debuglog "Authenticated"
        true
      end

      def keep_alive password
        if stream.is_disconnected?
          Jabber::debuglog "Stream disconnected. Connecting again..."
          connect(password)
        end
      end

      ## Callbacks

      CALLBACKS = %w(lobby_presence room_presence room_message private_message room_invite room_topic error)

      CALLBACKS.each do |callback_name|
        define_method("on_#{callback_name}") do |prio = 0, ref = nil, &block|
          callbacks[callback_name.to_sym].add(prio, ref) do |*args|
            block.call(*args)
          end
        end
      end

      def activate_callbacks
        stream.add_stanza_callback(0, self) do |stanza|
          case stanza.name
          when 'message'
            handle_message(HipChat::ReceivedMessage.new(stanza))
          when 'presence'
            handle_presence(HipChat::ReceivedPresence.new(stanza, chat_host))
          end
        end
        Jabber::debuglog "Callbacks activated"
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
          MUCBrowser.new(stream).muc_rooms(chat_host).keys.first.domain
        end
      rescue => e
        Jabber.logger.error("Conference host not found")
        nil
      end

      def stream
        @stream ||= Client.new(my_jid.strip) # TODO: Error Handling
      end

      def callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = CallbackList.new }
      end

      def handle_presence presence
        if presence.lobby?
          callbacks[:lobby_presence].process(
            presence.sender_id,
            presence.type
          )
        else
          callbacks[:room_presence].process(
            presence.room_id,
            # presence.user_id,
            presence.sender_name,
            presence.type,
            presence.role,
          )
        end
      end

      def handle_message message
        case message.type
        when :chat
          handle_private_message(message)
        when :groupchat
          if message.topic?
            handle_room_topic(message)
          else
            handle_group_message(message)
          end
        when :error
          handle_error(message)
        else
          handle_invite(message)
        end
      end

      def handle_invite message
        callbacks[:room_invite].process(
          message.room_id,
          message.room_name,
        )
      end

      def handle_private_message message
        callbacks[:private_message].process(
          message.sender_id,
          message.body,
        )
      end

      def handle_group_message message
        callbacks[:room_message].process(
          message.room_id,
          message.sender_name,
          message.body,
        )
      end

      def handle_room_topic message
        callbacks[:room_topic].process(
          message.room_id,
          message.topic,
        )
      end

      def handle_error message
        callbacks[:error].process(
          message.room_id,
          message.user_id,
          message.body,
          message.topic,
        )
      end
    end
  end
end
