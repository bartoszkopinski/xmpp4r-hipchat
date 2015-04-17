module Jabber
  module MUC
    module HipChat
      class UserData
        def initialize user
          @user = user
        end

        def jid
          @user.jid.to_s
        end

        def name
          @user.iname
        end

        def mention
          @user.attributes['mention_name']
        end

        def attributes
          {
               name: name,
            mention: mention,
          }
        end

        class << self
          def get_users_data stream
            @stream ||= stream
            @roster ||= Roster::Helper.new(stream, false) # TODO: Error handling

            loop do
              rosterget = Iq.new_rosterget
              rosterget.id = "roster_1"
              @stream.send(rosterget)
              @roster.wait_for_roster
              break if @roster.items.any?
              sleep(2)
            end

            @roster.items.map do |_, item|
              self.new(item)
            end
          end
        end
      end
    end
  end
end
