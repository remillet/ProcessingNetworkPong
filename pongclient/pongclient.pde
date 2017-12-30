import processing.net.*;


Client client;
float newMessageColor;
String messageFromServer;
String typing;

void setup()
{
  size(400, 200);
  client = new Client(this, "108.64.229.153", 5204);  // note my IP address as String, then using port 5204
  newMessageColor = 255;
  messageFromServer = "";
  typing = "";
}

void draw()
{
  background(255);
  fill(newMessageColor);
  textAlign(CENTER);
  text(messageFromServer, width/2, 140);
  newMessageColor = constrain(newMessageColor + 0.3f, 0, 255);

  fill(0);
  text("Type text and press Enter to send to server.", width/2, 60);
  text(typing, width/2, 80);
}

void clientEvent(Client client)
{
  String msg = client.readStringUntil('\n');
  if (msg != null)
  {
    messageFromServer = msg;
    newMessageColor = 0;
  }
}

void keyPressed()
{
  if (key == '\n')
  {
    client.write(typing);
    typing = "";
  } else
  {
    typing += key;
  }
}