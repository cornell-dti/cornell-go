import WebSocket from "ws";
import { startServer, waitForSocketState } from "./webSocketTestUtils";

const port = 80;

describe("WebSocket Server", () => {
  let server;
  beforeAll(async () => {
    server = await startServer(port);
  });
  afterAll(() => server.close());
  test("Server echoes the message it receives from client", async () => {
    // Create test client
    const client = new WebSocket(`ws://localhost:${port}`);
    await waitForSocketState(client, client.OPEN);
    const testMessage = "requestUserData";
    let responseMessage;
    client.on("updateUserData", (data) => {
      responseMessage = data;
      // Close the client after it receives the response
      client.close();
    });
    // Send client message
    client.send(testMessage);
    // Perform assertions on the response
    await waitForSocketState(client, client.CLOSED);
    expect(responseMessage).toBe(testMessage);
  });
});
