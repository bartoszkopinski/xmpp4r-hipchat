module Jabber
  module MUC
    module HipChat
      class RoomData
        ATTRIBUTES = [:id, :topic, :privacy, :is_archived, :guest_url, :owner, :last_active]
        attr_accessor *ATTRIBUTES

        def initialize room
          @room    = room
          room.first.children.each do |c|
            self.send("#{c.name}=", c.text)
          end
        end

        def attributes
          ATTRIBUTES.each_with_object({}) do |attribute, h|
            h[attribute] = self.send(attribute)
          end
        end
        alias_method :hipchat_id, :id

        def name
          @room.iname
        end

        def jid
          @room.jid.to_s
        end

        def archived?
          !!self.is_archived
        end

        class << self
          def get_rooms_data stream, conference_host
            iq = Iq.new(:get, conference_host)
            iq.from = stream.jid
            iq.add(Discovery::IqQueryDiscoItems.new)

            rooms = []
            stream.send_with_id(iq) do |answer|
              answer.query.each_element('item') do |item|
                rooms << self.new(item)
              end
            end
            rooms
          end
        end
      end
    end
  end
end
