#lang forge

/*
  Model of crypto/DS diagrams
  Tim and Mia
  Opting to build in normal Forge, not Electrum

   A            B
   |            |
   |----------->|
   |   {foo}_B  |
   |            |
   |<-----------|
   |   {bar}_A  |
       ...
       
time
|
v

*/

sig Datum {}

-- Alice, Bob, Eve, ...
-- an agent name is a datum
sig Agent extends Datum {} 

-- t=0, t=1, ...
sig Timeslot {
   tick: lone Timeslot 
}

-- {foo}_B
sig Message {
  -- Support delays, non-reception
  sender: one Agent,
  receiver: one Agent,
  sendTime: one Timeslot,
  recvTime: lone Timeslot,
  data: set Datum
}
-- Delay thinking about this: would raise Agent datum vs. Key datum distinction
--sig EncryptedMessage extends Message {
--  key: Agent
--}

pred wellformed {
  -- Design choice: only one message event per timeslot;
  --   assume we have a shared notion of time
  all t: Timeslot | lone sendTime.t + recvTime.t

  -- Receive no earlier than sent
  all m: Message | m.recvTime in (m.sendTime).^tick
}

inst instNSExploit { -- without crypto~
  Agent    = Alice + Bob + Eve
  Datum    = Agent
  Message  =  Message0 +  Message1 +  Message2 +  Message3 +  Message4 +  Message5
  Timeslot = Timeslot0 + Timeslot1 + Timeslot2 + Timeslot3 + Timeslot4 + Timeslot5
  tick = Timeslot0 -> Timeslot1 + Timeslot1 -> Timeslot2 + Timeslot2 -> Timeslot3 +
         Timeslot3 -> Timeslot4 +  Timeslot4 -> Timeslot5
  sender = Message0->Alice + Message1->Eve + Message2->Bob + Message3->Eve +
           Message4->Alice + Message5->Eve
  receiver = Message0->Eve + Message1->Bob + Message2->Eve + Message3->Alice +
             Message4->Eve + Message5->Bob
  sendTime = Message0->Timeslot0 + Message1->Timeslot1 + Message2->Timeslot2 +
             Message3->Timeslot3 + Message4->Timeslot4 + Message5->Timeslot5
  -- whoops? need double the times -- 12?
           
}

run {
  wellformed
} for instNSExploit

--option verbose 5
/*run {
  wellformed
}
for exactly 3 Agent, 7 Timeslot, 6 Message
for {tick is linear}
*/