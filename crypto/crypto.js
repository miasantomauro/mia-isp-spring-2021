
// these are in order because spec says they are linear
const timeslots = Timeslot.atoms(true);
const simpleTimeslots = timeslots.map((ts) => {return ts._id});
const agents = Agent.atoms(true);
const simpleAgents = agents.map((a) => {return a._id});

$(".script-stage").empty();

const container = $(".script-stage");

const messages = Message.atoms(true);

for (i = 0; i < messages.length; i++) {
    let id = messages[i]._id;
    let data = messages[i].data;
    let s = messages[i].sender;
    let r = messages[i].receiver;
    let st = messages[i].sendTime;
    let rt = messages[i].recvTime;
    container.append(`<p> ${s} sent ${id} containing ${data} at ${st} to ${r} who received it at ${rt} </p>`);
}
