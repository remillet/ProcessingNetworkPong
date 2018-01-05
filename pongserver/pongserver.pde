/*
2-Player Pong over a local Network using Processing (Processing.org)
Sean Fottrell, January 2018

Start running PongServer before running PongClient. PongClient should be
run on two different machines, one of which can be the same machine where
PongServer is running. The second line of PongClient's setup() method needs
to be modified so that it points to the IP address of the server. The default
address, 127.0.0.1, points to "localhost", or the same machine where that
client is running. So a client running on the same machine as the server
can leave the address as it is. Use "Network settings" to find
the local IP address where the server is running, and update the client
code for all other machines.
*/

import processing.net.*;

Server server;
int numPlayers = 0;
boolean startMsgSent = false;

void setup()
{
  size(200, 200);
  server = new Server(this, 5204);
}

void draw()
{
  if (!startMsgSent && numPlayers == 2)
  {
    server.write("y\n");
    startMsgSent = true;
  } else if (numPlayers >= 2)
  {
    // If there is no client, client will be null
    Client client = server.available();
    if (client != null)
    {
      String input = client.readStringUntil('\n');
      if (input != null)
      {
        server.write(input);
      }
    }
  }
}

// The serverEvent function is called whenever a new client connects.
void serverEvent(Server server, Client client)
{
  if (numPlayers == 0)
  {
     server.write("n1\n");  // code after 1st player logs in to set playerNum to 1
  }
  numPlayers++;
}