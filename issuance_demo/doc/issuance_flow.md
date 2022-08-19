# Issuance at didcomm level (Ideal flow)
This happens in background, after the user has scanned the QR-Code.

```mermaid
sequenceDiagram
participant w as Wallet
participant i as Issuance-Server

i->>w:  QR-Code: OOB-Message with credential Offer
w->>i: Propose credential with changed did
i->>w: Offer credential
w->>i: Request credential
i->>w: Issue Credential
w->>i: ACK

```

**Note**: The First offer-credential message is not embedded direcly in the QR-Code. Here, the link property of a Didcomm attachment is used. So the wallet must request the message from the server directly using http-get
