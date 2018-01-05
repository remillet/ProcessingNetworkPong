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
     server.write("n1\n");  // code for 1st player to login to set playerNum to 1
  }
  numPlayers++;
}