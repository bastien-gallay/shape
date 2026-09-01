---
title: Rotating the edge certificate
---

# Rotating the edge certificate

The edge certificate terminates TLS for every public request that reaches the
platform. It is issued for 90 days and the automation that was supposed to
renew it was retired in the gateway migration, so the rotation is manual until
the replacement lands. This page is what the on-call engineer follows, usually
under time pressure, when the expiry alarm fires at fourteen days.

There are two clusters behind the same certificate, `edge-west` and
`edge-east`. They are rotated one after the other so that a bad certificate
never takes both of them out at once.

## Before you start

You need shell access to the bastion host and membership of the `edge-ops`
group. The rotation cannot be done from a laptop — the certificate authority
only accepts requests from the bastion's source address.

Allow about forty minutes. Most of that is the certificate authority's
validation window, which is out of our hands.

## The rotation

### 1. Open the change window

Open a change window in the scheduling tool and announce it in the operations
channel. The window should be an hour, not forty minutes, because the
certificate authority has occasionally taken longer and a window that closes
mid-rotation forces a second announcement.

Expected result: the change window shows as active, and the operations channel
carries the announcement.

### 2. Generate the key and the signing request

On the bastion, generate a new private key and produce the signing request from
it:

```sh
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out edge-2026.key
openssl req -new -key edge-2026.key -out edge-2026.csr -subj "/CN=edge.example.net"
```

Expected result: both `edge-2026.key` and `edge-2026.csr` exist in the working
directory, and the key is 4096 bits.

### 3. Submit the signing request

Submit `edge-2026.csr` through the certificate authority portal, selecting the
`platform-edge` profile.

### 4. Wait for issuance and download the chain

We then wait for the issuance mail, which usually arrives within twenty
minutes, and download the full chain rather than the leaf certificate on its
own. The portal offers both and the leaf alone will pass a local check and then
fail in every browser, because the intermediate is not in the trust store.

Expected result: `edge-2026.pem` contains three certificates.

### 5. Verify the chain and the staple

Check that the downloaded chain verifies against the system roots and that the
OCSP staple is present:

```sh
openssl verify -untrusted edge-2026.pem edge-2026.pem
openssl s_client -connect edge.example.net:443 -status < /dev/null 2>&1 | grep -c "OCSP Response Status: successful"
```

⚠️ Do not skip the staple check. A chain that verifies locally but carries no
staple will be served happily by the gateway and rejected by the clients that
enforce stapling, which includes the two largest integrators. The failure looks
like an outage on their side, not ours, and it has cost us a day of
misdirected investigation before.

Expected result: the verify prints `OK` and the staple count is `1`.

### 6. Install on `edge-west`

Install the new certificate on `edge-west` first. You will need a vault token
scoped to `edge-ops` for this step; if you do not have one, request it from the
platform rotation and expect a ten-minute wait.

```sh
vault kv put secret/edge/west cert=@edge-2026.pem key=@edge-2026.key
edgectl reload --cluster edge-west
```

Expected result: `edgectl status --cluster edge-west` reports the new serial
number.

### 7. Run the staging probe

Run the staging probe against `edge-west`:

```sh
probe run edge-tls --cluster edge-west --strict
```

Expected result: all fourteen probe assertions pass.

### 8. Restart the fleet

Restart the `edge-east` fleet if the staging probe against `edge-west` came
back green.

Expected result: `edgectl status --cluster edge-east` reports the new serial
number and no connection errors in the first two minutes.

### 9. Close the change window

Close the change window and post the new expiry date in the operations channel.

Expected result: the window is closed and the expiry date is recorded.

## If it goes wrong

The previous certificate stays in the vault under `secret/edge/<cluster>/prev`
for thirty days. To roll back a cluster:

```sh
vault kv get -field=cert secret/edge/west/prev > rollback.pem
vault kv put secret/edge/west cert=@rollback.pem
edgectl reload --cluster edge-west
```

⚠️ Rolling back does not shorten the change window. Leave it open until the
rolled-back cluster has served clean traffic for ten minutes, because a
rollback that itself fails is the case where a closed window costs the most.

## Known problems

The certificate authority portal times out on requests submitted between 02:00
and 02:30, during its own maintenance. Submissions in that half hour appear to
succeed and never issue. Wait it out rather than resubmitting — a duplicate
request has to be revoked by hand and revocation takes a working day.

`edgectl reload` returns before the reload has finished. The status command is
the only reliable signal, and it can lag the reload by up to fifteen seconds.
