require 'pry'
require 'test/unit'
require 'xmpp4r/../../test/lib/clienttester'
require 'xmpp4r/muc'
require 'xmpp4r/semaphore'
# require_relative '../lib/xmpp4r/muc/hipchat_client'
include Jabber

class HipchatClientTest < Test::Unit::TestCase
  include ClientTester

  def test_new1
    m = MUC::HipchatClient.new(@client.jid)
    assert_equal(@client.jid, m.my_jid)
    assert_equal(@client.jid.domain, m.chat_domain)
    assert_equal(nil, m.conference_domain)
  end

  def test_complex
    # Jabber.debug = true
    m = MUC::HipchatClient.new(@client.jid)
    m.stream = @client

    block_args = []
    wait = Semaphore.new
    block = lambda { |*a| block_args = a; wait.run }
    m.on_message(&block)
    m.on_private_message(&block)
    m.on_presence(&block)
    m.on_invite(&block)
    # m.on_leave(&block)
    # m.on_self_leave(&block)

    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(@client.jid, pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/test'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='owner' role='moderator'/></x>" +
          "</presence>" +
          "<presence from='darkcave@macbeth.shakespeare.lit/secondwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='admin' role='moderator'/></x>" +
          "</presence>" +
          "<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
          "</presence>")
    }
    # m.my_jid = JID.new('hag66@shakespeare.lit/pda')
    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    wait_state

    state { |msg|
      assert_kind_of(Message, msg)
      assert_equal(:groupchat, msg.type)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), msg.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit'), msg.to)
      # assert_equal('TestCasing room', msg.subject)
      assert_nil(msg.body)
      send(msg.set_from('darkcave@macbeth.shakespeare.lit/thirdwitch').set_to('hag66@shakespeare.lit/pda'))
    }
    # assert_nil(m.subject)
    # wait.wait
    # m.subject = 'TestCasing room'
    # wait_state
    # wait.wait

    # FIXME : **Intermittently** failing (especially during RCOV run) at this line with:
    #   1) Failure:
    #   test_complex(HipchatClientTest) [./test/muc/tc_muc_HipchatClient.rb:71]:
    #   <[nil, "thirdwitch", "TestCasing room"]> expected but was
    #   <[nil, "secondwitch"]>.
    #
    #assert_equal([nil, 'thirdwitch', 'TestCasing room'], block_args)

    # FIXME : **Intermittently** failing (especially during RCOV run) at this line with:
    #   1) Failure:
    # test_complex(HipchatClientTest) [./test/muc/tc_muc_HipchatClient.rb:80]:
    # <"TestCasing room"> expected but was
    # <nil>.
    #
    #assert_equal('TestCasing room', m.subject)

  end

  def test_kick
    m = MUC::HipchatClient.new(@client.jid)
    m.stream = @client

    state { |presence|
      send("<presence from='test@test/test'/>")
    }
    m.join('test@test/test')
    wait_state

    state { |iq|
      assert_kind_of(Iq, iq)
      assert_equal('http://jabber.org/protocol/muc#admin', iq.queryns)
      assert_kind_of(MUC::IqQueryMUCAdmin, iq.query)
      assert_equal(1, iq.query.items.size)
      assert_equal('pistol', iq.query.items[0].nick)
      assert_equal(:none, iq.query.items[0].role)
      assert_equal('Avaunt, you cullion!', iq.query.items[0].reason)
      a = iq.answer(false)
      a.type = :result
      send(a)
    }
    m.kick('pistol', 'Avaunt, you cullion!')
    wait_state
  end
end
