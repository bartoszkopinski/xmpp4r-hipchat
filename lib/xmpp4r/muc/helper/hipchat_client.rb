module Jabber
  module MUC
    class HipchatClient
      attr_accessor :my_jid, :chat_domain, :conference_domain, :stream

      def initialize(jid)
        self.my_jid = JID.new(jid)
        self.stream = Client.new(my_jid.strip) # TODO: Error Handling
        Jabber::debuglog "Stream initialized"
        self.chat_domain = my_jid.domain

        @callbacks = Hash.new { |hash, key| hash[key] = CallbackList.new }
      end

      def join(jid, password = nil, opts = { history: false })
        room_jid = JID.new(jid)
        xmuc = XMUC.new
        xmuc.password = password

        if !opts[:history]
          history = REXML::Element.new('history').tap{ |h| h.add_attribute('maxstanzas','0') }
          xmuc.add_element history
        end

        room_jid.resource = name
        set_presence(:available, room_jid, nil, xmuc) # TODO: Handle all join responses
      end

      def exit(jid, reason = nil)
        room_jid = JID.new(jid)
        Jabber::debuglog "Exiting #{jid}"
        set_presence(:unavailable, room_jid, reason)
      end

      def keep_alive password
        if stream.is_disconnected?
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
          @callbacks[callback_name.to_sym].add(prio, ref) do |*args|
            block.call(*args)
          end
        end
      end

      def set_presence(type, to = nil, reason = nil, xmuc = nil, &block)
        pres      = Presence.new(:chat, reason)
        pres.type = type
        pres.to   = to if to
        pres.from = my_jid
        pres.add(xmuc) if xmuc
        stream.send(pres) { |r| block.call(r) }
      end

      def kick(recipients, room_jid)
        iq      = Iq.new(:set, room_jid)
        iq.from = my_jid
        iq.add(IqQueryMUCAdmin.new)
        recipients.each do |recipient|
          item      = IqQueryMUCAdminItem.new
          item.nick = recipient
          item.role = :none
          iq.query.add(item)
        end
        stream.send_with_id(iq)
      end

      def invite(recipients, room_jid)
        msg      = Message.new
        msg.from = my_jid
        msg.to   = room_jid
        x        = msg.add(XMUCUser.new)
        recipients.each do |jid|
          x.add(XMUCUserInvite.new(jid))
        end
        stream.send(msg)
      end

      def send_message(type, jid, text, subject = nil)
        message = Message.new(JID.new(jid), text.to_s)
        message.type    = type
        message.from    = my_jid
        message.subject = subject

        @send_thread.join if !@send_thread.nil? && @send_thread.alive?
        @send_thread = Thread.new do
          stream.send(message)
          sleep(0.2)
        end
      end

      def connect password
        stream.connect
        Jabber::debuglog "Connected to stream"
        stream.auth(password)
        Jabber::debuglog "Authenticated"
        @muc_browser = MUCBrowser.new(stream)
        Jabber::debuglog "MUCBrowser initialized"
        self.conference_domain = @muc_browser.muc_rooms(chat_domain).keys.first
        Jabber::debuglog "No conference domain found" if conference_domain.nil?
        @roster = Roster::Helper.new(stream) # TODO: Error handling
        @vcard  = Vcard::Helper.new(stream) # TODO: Error handling
        true
      end

      def activate_callbacks
        stream.add_presence_callback(150, self){ |presence| handle_presence(presence) }
        stream.add_message_callback(150, self){ |message| handle_message(message) }
        Jabber::debuglog "Callbacks activated"
      end

      def get_rooms
        iq = Iq.new(:get, conference_domain)
        iq.from = stream.jid
        iq.add(Discovery::IqQueryDiscoItems.new)

        rooms = []
        stream.send_with_id(iq) do |answer|
          answer.query.each_element('item') do |item|
            details = {}
            item.first.children.each{ |c| details[c.name] = c.text }
            rooms << {
              item:    item,
              details: details
            }
          end
        end
        rooms
      end

      def get_users
        @roster.wait_for_roster
        @roster.items.map do |jid, item|
          {
                jid: item.jid.to_s,
               name: item.iname,
            mention: item.attributes['mention_name'],
          }
        end
      end

      def get_user_details user_jid
        vcard = @vcard.get(user_jid)
        {
          email: vcard['EMAIL/USERID'],
          title: vcard['TITLE'],
          photo: vcard['PHOTO'],
        }
      end

      def deactivate_callbacks
        stream.delete_presence_callback(self)
        stream.delete_message_callback(self)
        Jabber::debuglog "Callbacks deactivated"
      end

      private

      def handle_presence(presence)
        from_jid      = presence.from.strip.to_s
        presence_type = presence.type.to_s
        user_name     = presence.from.resource

        if presence.from.domain == chat_domain
          @callbacks[:lobby_presence].process(from_jid, presence_type)
        else
          @callbacks[:room_presence].process(from_jid, user_name, presence_type)
        end
      end

      def handle_message(message)
        if is_invite?(message)
          handle_invite(message)
        elsif message.type == :chat
          handle_private_message(message)
        elsif message.type == :groupchat
          handle_group_message(message)
        elsif message.type == :error
          handle_error(message)
        end
      end

      def handle_invite(message)
        room_name = message.children.last.first_element_text('name')
        topic     = message.children.last.first_element_text('topic')
        room_jid  = message.from.strip.to_s
        user_name = message.from.resource
        @callbacks[:invite].process(room_jid, user_name, room_name, topic)
      end

      def handle_private_message(message)
        user_jid     = message.from.strip.to_s
        message_body = message.body.to_s
        @callbacks[:private_message].process(user_jid, message_body)
      end

      def handle_group_message(message)
        room_jid     = message.from.strip.to_s
        user_name    = message.from.resource
        message_body = message.body.to_s
        topic        = message.subject.to_s
        @callbacks[:room_message].process(room_jid, user_name, message_body, topic)
      end

      def handle_error(message)
        false
      end

      def is_invite?(message)
        !message.x.nil? && message.x.kind_of?(XMUCUser) && message.x.first.kind_of?(XMUCUserInvite)
      end
    end
  end
end
