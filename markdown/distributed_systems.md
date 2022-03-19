# Distributed Systems

## Definitions

  * What is a distributed system?
    - Nodes connected by LAN/WAN
    - Communication only via messages (fiber, cable, satellite)
    - Message time >> Event time
    - Lamport's definition: A system is distributed if the message transmission time is not
    negligible compared to the time between events in a single process
      + Even a cluster is a distributed system
      + If the time to pass messages outweighs the computation time, there's no gain
  * Distributed System Example
    - Booking a flight through Expedia; communication between user, Expedia, Delta
    - Beliefs
      + Processes are sequential, events are totally ordered (d->e, f->g, h->i)
      + Send before receive (a->b, e->f)
      + Called the "happened before" relationship

| ![example](images/ds_example.png) |
|:--:|
| Distributed System Example |

  * Happened Before Relation
    - If a happened before b (a->b)...
      + a and b are executing in the same process, or...
      + A communication event happens that connects a and b
    - Transitive (a->b, b->c then a->c)
    - If two events aren't connected by a happened-before relation, they're concurrent events
    - Happened before is insufficient for creating a total order of events
