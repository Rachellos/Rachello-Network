#define MSG_LENGTH		256

public void SayText2(int client, int author, const char[] message)
{
	Handle hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, "");
	EndMessage();
}