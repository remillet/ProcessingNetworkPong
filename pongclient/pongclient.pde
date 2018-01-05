import processing.net.*;


Client client;
String input; // format: "recentHit,paddle1Y,paddle2Y,ballX,ballY,ballXSpeed,ballYSpeed"
// input will be read from server and used to update client's display.
// Client will then move paddle (optionally), move ball, and write new data to the server.
float[] data; // parsed version of input from perspective of this client (myPaddle):
// format: Paddle1Y,Paddle2Y,ballX,ballY,ballXSpeed,ballYSpeed

int plNum; // playerNum is either 1 or 2. The server picks this and sends it at start of game
int count = 0;
int ballSize;
float ballX, ballY;
float ballSpeedX, ballSpeedY;
float paddleSpeed = 2;
int paddleLength = 40;
int paddleWidth = 10;
int wallWidth = 10;
float myPaddleY, myPrevPaddleY;
int p1Edge;  // right edge of left paddle (front edge)
int tBound;
int bBound;
int p2Edge;  // left edge of right paddle (front edge)
boolean readyToPlay = false;
boolean missed = false;  // if ball goes past the front of your paddle
boolean knocked = false; // if ball was hit by end of your paddle
boolean recentHit = false;
int recentOpponentHit = 0;  // if input shows a recentHit (first character is a 1)
// then this is holds number of frames during which opponent ball's data should be 
// read from input instead of calculated locally


void setup()
{
  size(600, 400);
  client = new Client(this, "127.0.0.1", 5204);  // note my IP address as String, then using port 5204

  plNum = 0;  

  ballSize = 20;
  tBound = 5;
  bBound = height - 5;
  p1Edge = 15;
  p2Edge = width - 15;
  ballX = width / 2;
  ballY = height / 2;
  ballSpeedX = 3;
  ballSpeedY = 1;
  myPaddleY = 100;
  data = new float[6];
  data[0] = 100;
  data[1] = 100;
  data[2] = ballX;
  data[3] = ballY;
  data[4] = ballSpeedX;
  data[5] = ballSpeedY;
}


void draw()
{
  getDataFromServer();
  if (readyToPlay)
  {
    drawCourt();
    updateMyPaddle();
    advanceBall();
    writeDataToServer();
  }
}


void getDataFromServer()
{
  if (client.available() > 0)
  {
    count++;
    input = client.readStringUntil('\n');
    //print("count: " + count + "   input: " + input);
    //println("char1: " + input.charAt(1) + "    plNum: " + plNum + "\n");
    if (input != null)
    {
      if (input.charAt(1) == '1' && plNum == 0)
      {
        plNum = 1;
        //println("PlayerNum: " + plNum);
      } else if (input.charAt(0) == 'y')
      {
        readyToPlay = true;
        if (plNum == 0)
        {
          plNum = 2;
        }
      } else
      {
        if (input.charAt(0) == '1')  // recent hit
        {
          if ((plNum == 1 && ballX > width/2) || (plNum == 2 && ballX < width/2))
          {
            recentOpponentHit = 5;  // for next 5 frames, get ball data from input
          }                         // 5 is somewhat arbitrary; could try fewer or more
        }

        input = input.substring(2);
        data = float(splitTokens(input, ",\n"));
      }
    }
  }
}


void drawCourt()
{
  // Draw top and bottom walls
  background(0);
  strokeWeight(wallWidth);
  stroke(255);
  line(p1Edge, tBound, p2Edge, tBound);
  line(p1Edge, bBound, p2Edge, bBound);

  // Draw ball
  strokeWeight(1);
  ellipse(ballX, ballY, ballSize, ballSize);

  // Draw paddles
  fill(255);
  rectMode(CORNER);
  if (plNum == 1)
  {
    rect(p1Edge - paddleWidth, myPaddleY, paddleWidth, paddleLength);  // myPaddle
    rect(p2Edge, data[1], paddleWidth, paddleLength);  // theirPaddle
  } else
  {
    rect(p2Edge, myPaddleY, paddleWidth, paddleLength);  // myPaddle
    rect(p1Edge - paddleWidth, data[0], paddleWidth, paddleLength);  // theirPaddle
  }
}


void updateMyPaddle()
{
  if (keyPressed)
  {
    if (key == CODED)
    {
      if (keyCode == UP)
      {
        myPaddleY -= paddleSpeed;
      }
      if (keyCode == DOWN)
      {
        myPaddleY += paddleSpeed;
      }
    }
  }
  myPaddleY = constrain(myPaddleY, tBound - paddleLength/2, bBound - paddleLength/2);
  if (plNum == 1)
  {
    data[0] = myPaddleY;
  } else
  {
    data[1] = myPaddleY;
  }
}


void advanceBall()
{
  if (recentOpponentHit > 0)  // Don't know if this hit counter is needed;
  {                           // An attempt to make sure that your load opponent's version of data
    ballX = data[2];          // after they get a hit
    ballY = data[3];
    ballSpeedX = data[4];
    ballSpeedY = data[5];
    recentOpponentHit--;
  } else
  {
    ballX += ballSpeedX;
    ballY += ballSpeedY;

    // if ball hits top or bottom
    if (ballY <= tBound + ballSize/2 + wallWidth/2 || ballY >= bBound - ballSize/2 - wallWidth/2)
    {
      ballSpeedY = ballSpeedY * -1;
    }

    // if ball gets to myPaddle...
    if (plNum == 1)
    {
      if (ballX <= p1Edge + ballSize/2)
      {
        // if ball alligned vertically with paddle
        if (ballY >= myPaddleY - ballSize/2 && ballY <= myPaddleY + paddleLength + ballSize/2)
        {
          recentHit = true;
          if (!missed)
          {
            // Adjust y-speed based on where ball strikes paddle
            ballSpeedX = ballSpeedX * -1;
            if (ballY < myPaddleY + .15 * paddleLength)
            {
              ballSpeedY =  ballSpeedY - .8;
            } else if (ballY < myPaddleY + .3 * paddleLength)
            {
              ballSpeedY = ballSpeedY - .3 ;
            } else if (ballY > myPaddleY + .85 * paddleLength)
            {
              ballSpeedY = ballSpeedY + .8;
            } else if (ballY > myPaddleY + .7 * paddleLength)
            {
              ballSpeedY = ballSpeedY + .3 ;
            }
          }
          if (missed && !knocked)
          {
            knocked = true;
            if (ballX >= p1Edge - paddleWidth)
            {
              ballSpeedY = -ballSpeedY + 2 * (myPaddleY - myPrevPaddleY);
            }
          }
        } else
        {
          missed = true;
        }
      }
    } else
    {
      if (ballX >= p2Edge - ballSize/2)
      {
        // if ball alligned vertically with paddle
        if (ballY >= myPaddleY - ballSize/2 && ballY <= myPaddleY + paddleLength + ballSize/2)
        {
          recentHit = true;
          if (!missed)
          {
            // Adjust y-speed based on where ball strikes paddle
            ballSpeedX = ballSpeedX * -1;
            if (ballY < myPaddleY + .15 * paddleLength)
            {
              ballSpeedY =  ballSpeedY - .8;
            } else if (ballY < myPaddleY + .3 * paddleLength)
            {
              ballSpeedY = ballSpeedY - .3 ;
            } else if (ballY > myPaddleY + .85 * paddleLength)
            {
              ballSpeedY = ballSpeedY + .8;
            } else if (ballY > myPaddleY + .7 * paddleLength)
            {
              ballSpeedY = ballSpeedY + .3 ;
            }
          }
          if (missed && !knocked)
          {
            knocked = true;
            if (ballX <= p2Edge + paddleWidth)
            {
              ballSpeedY = -ballSpeedY + 2 * (myPaddleY - myPrevPaddleY);
            }
          }
        } else
        {
          missed = true;
        }
      }
    }
    if ((plNum == 1 && ballX < width/2) || (plNum == 2 && ballX > width/2))
    {
      data[2] = ballX;
      data[3] = ballY;
      data[4] = ballSpeedX;
      data[5] = ballSpeedY;
    }
  }
  myPrevPaddleY = myPaddleY;
}


boolean offScreen()
{
  if (plNum == 1)
  {
    return ballX < 0;
  } else
  {
    return ballX > width;
  }
}


void writeDataToServer()
{
  if (frameCount % 5 == 0 || recentHit || offScreen())  // frameCount%5 is a compromise between
  {                                                // jerky motion and not overwhelming server
    String output = "";

    if (offScreen())
    {
      output += "1,";  // sends "recentHit" code to opponent so that their display updates
      knocked = false;
      missed = false;
      ballX = width/2;
      data[2] = ballX;
      ballY = height/2;
      data[3] = ballY;
      ballSpeedY = 1;  // maybe don't change this?? so next serve is same angle as missed one??
      data[5] = ballSpeedY;
      // Don't change ball's x speed: gets launched back to same player that missed it.
      
    } else if (recentHit)
    {
      output += "1,";
      recentHit = false;
    } else
    {
      output += "0,";
    }

    output += data[0] + "," + data[1] + "," + data[2] + "," + data[3] + "," + data[4] + "," + data[5] + "\n";
    client.write(output);
  }
}