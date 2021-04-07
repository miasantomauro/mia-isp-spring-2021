/*inst boundedDemo {
Agent = Alice + Bob + Eve
Attacker = Eve

Timeslot = Timeslot0 + Timeslot1 + Timeslot2 + Timeslot3 + Timeslot4

Datum = Agent + na + nb + nc + Ciphertext0 + Ciphertext1 + Ciphertext2 + Ciphertext3 + Ciphertext4 + PubKa + PubKb + PrivKa + PrivKb + PrivKc + PubKc  

Ciphertext = Ciphertext0 + Ciphertext1 + Ciphertext2 + Ciphertext3 + Ciphertext4

plaintext in Ciphertext0->na + Ciphertext0->Alice + Ciphertext1->na + Ciphertext1->Alice + Ciphertext2->na + Ciphertext2->nb + Ciphertext3->nb + Ciphertext4->nb + Ciphertext4->na + Ciphertext4->PubKc + Ciphertext4->PubKb
encryptionKey in Ciphertext0->PubKc + Ciphertext1->PubKb + Ciphertext2->PubKa + Ciphertext3->PubKc + Ciphertext4->PubKb + Ciphertext4->PubKc + Ciphertext4->PubKb

plaintext ni Ciphertext0->na + Ciphertext0->Alice + Ciphertext1->na + Ciphertext1->Alice + Ciphertext2->na + Ciphertext2->nb + Ciphertext3->nb + Ciphertext4->nb
encryptionKey ni Ciphertext0->PubKc + Ciphertext1->PubKb + Ciphertext2->PubKa + Ciphertext3->PubKc + Ciphertext4->PubKb

Key = PubKa + PubKb + PrivKa + PrivKb + PubKc + PrivKc
PrivateKey = PrivKb + PrivKa + PrivKc
PublicKey = PubKa + PubKb + PubKc

Message = Message0 + Message1 + Message2 + Message3 + Message4
sender = Message0->Alice + Message1->Alice + Message2->Bob + Message3->Alice + Message4->Alice
receiver = Message0->Bob + Message1->Bob + Message2->Alice + Message3->Bob + Message4->Bob

data = Message0->Ciphertext0 + Message1->Ciphertext1 + Message2->Ciphertext2 + Message3->Ciphertext3 + Message4->Ciphertext4
sendTime = Message0->Timeslot0 + Message1->Timeslot1 + Message2->Timeslot2 + Message3->Timeslot3 + Message4->Timeslot4 

tick = Timeslot0->Timeslot1 + Timeslot1->Timeslot2 + Timeslot2->Timeslot3 + Timeslot3->Timeslot4

KeyPairs = KP1
pairs = KP1->PrivKa->PubKa + KP1->PrivKb->PubKb + KP1->PrivKc->PubKc
owners = KP1->PrivKa->Alice + KP1->PrivKb->Bob 

attacker = Message3->Eve + Message0->Eve
new_message = Message3->Message4 + Message0->Message1

Orig = O1
uniqOrig = O1->na->Alice + O1->nb->Bob
}*/

/*
inst paperExploit {
Agent = Alice + Bob + Eve
Attacker = Eve

Timeslot = Timeslot0 + Timeslot1 + Timeslot2 + Timeslot3 + Timeslot4

Datum = Agent + na + nb + Ciphertext0 + Ciphertext1 + Ciphertext2 + Ciphertext3 + Ciphertext4 + PubKa + PubKb + PrivKa + PrivKb + PrivKc + PubKc  

Ciphertext = Ciphertext0 + Ciphertext1 + Ciphertext2 + Ciphertext3 + Ciphertext4

plaintext = Ciphertext0->na + Ciphertext0->Alice + Ciphertext1->na + Ciphertext1->Alice + Ciphertext2->na + Ciphertext2->nb + Ciphertext3->nb + Ciphertext4->nb
encryptionKey = Ciphertext0->PubKc + Ciphertext1->PubKb + Ciphertext2->PubKa + Ciphertext3->PubKc + Ciphertext4->PubKb
Key = PubKa + PubKb + PrivKa + PrivKb + PubKc + PrivKc
PrivateKey = PrivKb + PrivKa + PrivKc
PublicKey = PubKa + PubKb + PubKc

Message = Message0 + Message1 + Message2 + Message3 + Message4
sender = Message0->Alice + Message1->Alice + Message2->Bob + Message3->Alice + Message4->Alice
receiver = Message0->Bob + Message1->Bob + Message2->Alice + Message3->Bob + Message4->Bob

data = Message0->Ciphertext0 + Message1->Ciphertext1 + Message2->Ciphertext2 + Message3->Ciphertext3 + Message4->Ciphertext4
sendTime = Message0->Timeslot0 + Message1->Timeslot1 + Message2->Timeslot2 + Message3->Timeslot3 + Message4->Timeslot4 

tick = Timeslot0->Timeslot1 + Timeslot1->Timeslot2 + Timeslot2->Timeslot3 + Timeslot3->Timeslot4

KeyPairs = KP1
pairs = KP1->PrivKa->PubKa + KP1->PrivKb->PubKb + KP1->PrivKc->PubKc
owners = KP1->PrivKa->Alice + KP1->PrivKb->Bob 

attacker = Message3->Eve + Message0->Eve
new_message = Message3->Message4 + Message0->Message1

Orig = O1
uniqOrig = O1->na->Alice + O1->nb->Bob
}*/


/*inst instNSExploit { 
  -- Alice is init in this case
  Agent = Alice + Bob + Eve
  Attacker = Eve

  Timeslot in Timeslot0 + Timeslot1 + Timeslot2 + Timeslot3 + Timeslot4
  Timeslot ni Timeslot0 + Timeslot1 + Timeslot2 

  Datum in Agent + n1 + n2 + n3 + Ciphertext0 + Ciphertext1 + Ciphertext2 + Ciphertext3 + Ciphertext4 + PubKa + PubKb + PrivKa + PrivKb + PrivKc + PubKc  
  Datum ni Agent + n1 + n2 + Ciphertext0 + Ciphertext1 + Ciphertext2 + PubKa + PubKb + PrivKa + PrivKb

  Ciphertext in Ciphertext0 + Ciphertext1 + Ciphertext2 + Ciphertext3 + Ciphertext4
  Ciphertext ni Ciphertext0 + Ciphertext1 + Ciphertext2 

  plaintext in Ciphertext0->n1 + Ciphertext0->Alice + Ciphertext1->n1 + Ciphertext1->n2 + Ciphertext2->n2 + Ciphertext3->Alice + Ciphertext3->n1 + Ciphertext4->n2
  plaintext ni Ciphertext0->n1 + Ciphertext0->Alice + Ciphertext1->n1 + Ciphertext1->n2 + Ciphertext2->n2
  
  encryptionKey in Ciphertext0->PubKb + Ciphertext1->PubKa + Ciphertext2->PubKb + Ciphertext3->PubKb + Ciphertext3->PubKa + Ciphertext3->PubKc + Ciphertext4->PubKc
  encryptionKey ni Ciphertext0->PubKb + Ciphertext1->PubKa + Ciphertext2->PubKb

  Key in PubKa + PubKb + PrivKa + PrivKb + PubKc + PrivKc
  Key ni PubKa + PubKb + PrivKa + PrivKb

  PrivateKey in PrivKa + PrivKb + PrivKc
  PrivateKey ni PrivKa + PrivKb

  PublicKey in PubKa + PubKb + PubKc
  PublicKey ni PubKa + PubKb

  Message in Message0 + Message1 + Message2 + Message3 + Message4
  Message ni Message0 + Message1 + Message2

  sender in Message0->Alice + Message1->Bob + Message2->Alice + Message3->Alice + Message3->Bob + Message3->Eve + Message4->Alice
  sender ni Message0->Alice + Message1->Bob + Message2->Alice

  receiver in Message0->Bob + Message1->Alice + Message2->Bob + Message3->Alice + Message3->Bob + Message4->Bob
  receiver ni Message0->Bob + Message1->Alice + Message2->Bob

  data in Message0->Ciphertext0 + Message1->Ciphertext1 + Message2->Ciphertext2 + Message3->Ciphertext3 + Message4->Ciphertext4 + Message3->Ciphertext2 + Message3->Ciphertext1
  data ni Message0->Ciphertext0 + Message1->Ciphertext1 + Message2->Ciphertext2

  sendTime = Message0->Timeslot0 + Message1->Timeslot2 + Message2->Timeslot3 + Message3->Timeslot1 + Message4->Timeslot4 
  --sendTime ni Message0->Timeslot0 + Message1->Timeslot1 + Message2->Timeslot2

  tick = Timeslot0->Timeslot1 + Timeslot1->Timeslot2 + Timeslot2->Timeslot3 + Timeslot3->Timeslot4

  KeyPairs = KP1
  pairs = KP1->PrivKa->PubKa + KP1->PrivKb->PubKb + KP1->PrivKc->PubKc
  owners in KP1->PrivKa->Alice + KP1->PrivKb->Bob + KP1->PrivKc->Alice + KP1->PrivKc->Bob
  owners ni KP1->PrivKa->Alice + KP1->PrivKb->Bob

  new_message = Message0->Message3 + Message2->Message4

  Orig = O1
  uniqOrig = O1->n1->Alice + O1->n2->Bob

}*/

/*inst tickInstance {tick is linear} 

run {
  wellformed
} for paperExploit*/

/*run {
  wellformed
} for exactly 3 Agent, 8 Timeslot, exactly 2 Message, exactly 1 Ciphertext, exactly 1 SymmetricKey, exactly 1 PublicKey, exactly 1 PrivateKey, exactly 10 Datum for {tick is linear}*/
