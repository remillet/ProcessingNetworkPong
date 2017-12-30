import processing.net.*;

Server server;
float newMessageColor;
String incomingMessage;

void setup()
{
  size(400, 200);
  server = new Server(this, 5204);
  newMessageColor = 255;
  incomingMessage = "";
}

void draw()
{
  background(newMessageColor);

  // newMessageColor fades to white over time
  newMessageColor = constrain(newMessageColor + 0.3f, 0, 255);
  textAlign(CENTER);
  fill(255);
  text(incomingMessage, width/2, height/2);

  // If there is no client, client will be null
  Client client = server.available();
  if (client != null)
  {
    // Receive the message
    incomingMessage = client.readString();
    incomingMessage = incomingMessage.trim();

    // Print to Processing message window
    System.out.println("Client says: " + incomingMessage);

    // Write message back out (note this goes to ALL clients)
    server.write("How does " + incomingMessage + " make you feel?\n");
    newMessageColor = 0;
  }
}

// The serverEvent function is called whenever a new client connects.
void serverEvent(Server server, Client client)
{
  incomingMessage = "A new client has connected: " + client.ip();
  System.out.println(incomingMessage);
  newMessageColor = 0;
}