require 'spec_helper'

module Jabber
  module MUC
    describe HipchatClient do
      let(:client_jid){ '00000_000000@chat.hipchat.com' }
      let(:room_jid){ '00000_room@conf.hipchat.com' }

      subject{ described_class.new(client_jid) }

      describe '#initialize' do
        it 'assigns JID' do
          expect(subject.my_jid.to_s).to eq(client_jid)
        end

        it 'assigns chat host' do
          expect(subject.chat_host).to eq('chat.hipchat.com')
        end

        it 'creates new stream client' do
          expect(subject.stream).to be_instance_of(Jabber::Client)
        end
      end

      describe '#exit' do
        it 'sets unavailable presence' do
          expect(subject).to receive(:set_presence).with(:unavailable, anything, anything)
          subject.exit(room_jid)
        end
      end

      describe '#join' do
        it 'sets available presence' do
          expect(subject).to receive(:set_presence).with(:available, anything, anything, anything)
          subject.join(room_jid)
        end
      end

      describe '#name' do
        it 'returns JID resource' do
          subject.name = 'client name'
          expect(subject.name).to eq('client name')
        end
      end

      describe '#set_presence' do
        it 'sends a new presence to the stream' do
          expect(subject.stream).to receive(:send).with(kind_of(Jabber::Presence))
          subject.set_presence(:type)
        end
      end

    end
  end
end
