---
title: Choosing a job queue for the ingest pipeline
---

# Choosing a job queue for the ingest pipeline

The ingest pipeline currently has no queue. Uploaded batches are written to a
table and a cron job picks them up every minute, which was fine when the
service handled forty batches a day and is not fine now that it handles nine
thousand. We need to choose what replaces it before the next ingest season
opens, and this page records what was considered.

## Background

A batch is between two and four hundred megabytes and takes anywhere from ten
seconds to nine minutes to process. Failures are common and mostly transient:
the upstream metadata service is unreliable and roughly one batch in fifty has
to be retried. Ordering does not matter between batches but does matter within
a batch, and a batch that is processed twice produces duplicate rows that are
expensive to reconcile afterwards.

We process nothing at night, so the load is bursty: about seventy per cent of a
day's batches arrive in a four-hour window. Two engineers maintain the
pipeline, neither of them full time.

## What we looked at

The first thing we looked at was keeping what we have and making it better. The
cron-and-table approach is understood by everybody on the team and there is no
new infrastructure to run. We did not pursue it.

A managed cloud queue was the second option. It gives us retries, dead-letter
handling and visibility timeouts without our writing any of it, and the
operational burden is close to zero, which matters a great deal for a team of
two half-time engineers. Against it: the batches are too large to put in a
message, so we would be passing object-store references and the queue would
only carry pointers, which means the at-least-once delivery guarantee applies
to the pointer and not to the work. We would still have to build our own
deduplication. There is also the cost, which at nine thousand batches a day and
the current retry rate we estimated at
around two hundred and forty euros a month, and the fact that it ties the
pipeline to one provider at a point where the wider platform is trying to
reduce exactly that kind of coupling.

Redis streams came up next, mostly because we already run Redis for the session
cache and adding a stream to it looked free. It is fast, the consumer-group
model fits the shape of the work well, and the team has used it before in
another context. The problem is durability. Our Redis is configured for cache
semantics — no append-only file, and a failover loses whatever was in memory.
Reconfiguring it for durability would mean either changing the settings for the
session cache too, which nobody wants, or running a second Redis, at which
point the "we already run it" argument disappears entirely. We also measured
the memory ceiling and a four-hour burst at current volumes would need more
memory than the instance has.

Finally we looked at a queue built on the Postgres instance we already have,
using `SELECT ... FOR UPDATE SKIP LOCKED`. It is a well-understood pattern, it
gives us transactional enqueue — the batch row and the queue entry commit
together, which removes a whole class of the duplicate problem described above
— and it needs no new infrastructure and no new provider relationship. The
throughput we need is far below what the pattern is known to handle. Against
it: we have to write the retry and dead-letter logic ourselves, perhaps three
hundred lines, and we put more load on a database that is already the busiest
thing we run, though the queue traffic is small next to the ingest writes
themselves.

## What we are doing

We will probably go with the Postgres queue. Transactional enqueue is worth
more to us than the managed retry logic is, because the duplicate-row problem
is the one that has actually cost us time this year, and the retry logic is
three hundred lines we know how to write. The provider coupling argument
against the managed queue was the weakest of the three and would not have
decided it on its own.

The week of measurement was spent on a copy of the production instance,
replaying a season's worth of recorded batches through a prototype of each of
the two options we took seriously. The Postgres prototype held at four times
current peak with the database sitting at under a third of its connection
limit; the managed queue held too, and the number that decided it was not
throughput but the twelve duplicate rows the pointer-based prototype produced
over the replay, against none for the transactional one.

The main thing that would change our mind is the database load. If ingest
volume grows another five times, the queue traffic stops being small next to
the writes and we should expect to revisit this. We would move to the managed
queue at that point rather than to Redis, since the durability objection to
Redis does not go away with scale.

Decided 2026-05-14 by the ingest pair, after a week of measurement on a copy of
the production instance.
