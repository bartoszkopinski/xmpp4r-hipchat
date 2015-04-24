module Jabber
  module MUC
    module HipChat
      class RoomData
        # ATTRIBUTES = [:id, :topic, :privacy, :is_archived, :guest_url, :owner, :last_active, :num_participants]
        attr_accessor :attributes

        def initialize room
          @room       = room
          @attributes = {
            "name" => name,
            "id" => id,
          }

          room.first.children.each do |c|
            @attributes[c.name] ||= c.text
          end
        end

        def name
          @room.iname
        end

        def id
          @room.jid.node
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
