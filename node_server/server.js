const WebSocket = require("ws");
const express = require("express");
const moment = require("moment");
const axios = require("axios");

const app = express();
const port = 8000; // port for https

app.get("/", (req, res) => {
  res.send("Express server is running");
});

app.listen(port, () => {
  console.log(`Example app listening at http://127.0.0.1:${port}`);
});

var webSockets = {};

const wss = new WebSocket.Server({ port: 6060 }); // run websocket server with port 6060

wss.on("connection", function (ws, req) {
  var userID = req.url.substr(1); // get userid from URL ip:6060/userid
  webSockets[userID] = ws; // add new user to the connection list
  console.log("User " + userID + " Connected");

  ws.on("message", async (message) => {
    // Convert the message buffer to a string
    const datastring = message.toString();
    console.log("Received message: ", datastring);

    // Proceed with your existing logic
    if (datastring.charAt(0) === "{") {
      const sanitizedDataString = datastring.replace(/\'/g, '"');
      try {
        const data = JSON.parse(sanitizedDataString);
        if (data.auth === "addauthkeyifrequired") {
          if (data.cmd === "send") {
            const cdata = JSON.stringify({
              cmd: data.cmd,
              userid: data.userid,
              msgtext: data.msgtext,
            });

            try {
              ws.send(cdata); // send message back to the sender
              console.log("Message echoed back to sender");
              ws.send(data.cmd + ":success");

              // Save message to Strapi
              const token = "8df73c7483475a38a5689ccf1348ddf0da164bb6adba864b6e94451478785cfb919655364c3097cd35bee079e6b7f8b77edd0b7d8d7a70a8623e65896121126c1dec0277c0b946191074f6e9ed61030d58878ef5cce1f4d6946b1b75cb9fe904a58be3fbbe98e7e7da8dced6e51f1af9b4a6b31abba72f96ac7f509e5d805239"; // Replace with your actual token
              await axios.post(
                "http://localhost:1337/api/messages",
                {
                  data: {
                    cmd: data.cmd,
                    userid: data.userid,
                    msgtext: data.msgtext,
                    timestamp: moment().format(),
                  },
                },
                {
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );
            } catch (error) {
              console.error("Error:", error);
              ws.send(data.cmd + ":error");
            }
          } else {
            console.log("No send command");
            ws.send(data.cmd + ":error");
          }
        } else {
          console.log("App Authentication error");
          ws.send(data.cmd + ":error");
        }
      } catch (error) {
        console.error("Error parsing JSON:", error);
        ws.send("error: invalid JSON format");
      }
    } else {
      console.log("Non-JSON type data");
      ws.send("error: non-JSON type data");
    }
  });

  ws.on("close", function () {
    var userID = req.url.substr(1);
    delete webSockets[userID]; // on connection close, remove receiver from connection list
    console.log("User Disconnected: " + userID);
  });

  ws.send("connected"); // initial connection return message
});