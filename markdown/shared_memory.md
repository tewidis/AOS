# Parallel Systems

## Shared Memory Machines

    * Shared Memory Machine Models
        1. Dance hall architecture: CPUs on one side, memory on other side of
        interconnection network

| ![dance_hall](images/shm_dance_hall.png) |
|:--:|
| Dance Hall Architecture |

        2. Symmetric Multiprocessor: Bus connects CPUs to memory

| ![symmetric](images/shm_symmetric_multiprocessor.png) |
|:--:|
| Symmetric Multiprocessor Architecture |

        3. Distributed Shared Memory: Each CPU has nearby memory, but all memory
        is accessible by all CPUs

| ![distributed](images/shm_distributed_model.png) |
|:--:|
| Distributed Shared Memory Architecture |

    * Shared Memory and Caches
        - Accessing cache: ~2 cycles
        - Accessing memory: 100+ cycles
        - Issue: Memory shared across processors, caches are private to CPU
            + When one CPU writes to its cache, all of the others must be 
            updated to stay in sync
            + Need to maintain consistency
    * Memory Consistency Models
        - Sequential consistency - Leslie Lamport, 1977
            + Program order (order in which a process generates memory accesses) 
            is maintained
            + Arbitrary interleaving between processes
    * Memory Consistency and Cache Coherence
        - Process P1: a = a + 1; b = b + 1;
        - Process P2: d = b; c = a;
        - What are possible values for d and c?
            + c = d = 0 (Yes)
            + c = d = 1 (Yes)
            + c = 1, d = 0 (Yes)
            + c = 0, d = 1 (Not possible with sequential consistency)
        - Memory consistency: What is the model presented to the programmer?
        - Cache coherence: How is the system implementing the model in the 
        presence of private caches?
        - Non-Cache Coherent Shared Multiprocessor: System software is required 
        to maintain consistency across caches, hardware only provides shared 
        address space (NCC)
        - Cache Coherent Shared Multiprocessor: Hardware does everything (CC)
    * Hardware Cache Coherence
        - Write invalidate: If a particular memory location is in multiple 
        caches and one CPU updates it, it will send an "invalidate" signal on
        the bus to all other CPUs (CPUs know to fetch the new value)
        - Write update: If a particular memory location is in multiple caches and 
        one CPU updates it, the hardware will send an "update" message to change
        the values in the other CPUs
        - Want to minimize overhead, but grows with number of CPUs
    * Scalability
        - Expectation is that performance should increase with more processors
        - However, synchronization overhead increases with number of processors
        as well
        - "Shared memory machines scale well when you don't share memory" - Chuck
        Thacker

## Synchronization

    * Synchronization Primitives
        - Exclusive lock: One thread can hold a lock at a time
        - Shared lock: Multiple threads hold lock to read
        - Barrier: Provide guarantee that all threads have reached a particular
        point
    * Atomic Operations
        - Simple atomic read/write primitives are insufficient for implementing
        a lock
            + Groups of reads/writes are not atomic and could be interleaved
            + Requires "read-modify-write" instruction (RMW)
        - Atomic RMW Instructions
            + test_and_set(L): return current value in L, set L to 1
            + fetch_and_increment(L): return current value in L, increment L
    * Scalability Issues with Synchronization
        - Latency: How long does it take to acquire a lock?
        - Contention: When multiple threads are attempting to acquire the lock,
        how long does it take for one to win?
        - Waiting time: How long will a thread wait to acquire a lock?
            + Application-dependent
    * Native Spinlock (spin on test_and_set)
        - lock(L):  
            + while( test_and_set(L) == locked );
        - unlock(L):
            + L = unlocked;
        - Problems with Native Spinlock
            + Too much contention (all threads are spinning on the memory location)
            + Does not exploit caches (can't use cached value because multiple 
            threads are sharing the same atomic memory location)
            + Disrupts useful work (contention impedes other threads from doing
            useful work)
    * Caching Spinlock (spin on read)
        - Spin on value in local cache, then try test_and_set when unlocked
        - lock(L):
            + while( L == locked );
            + if( test_and_set(L) == locked) go back;
        - Problems with Caching Spinlock
            + All CPUs will see the update at the same time and try to acquire
            the lock at the same time (doesn't solve contention issue)
            + This results in heavy bus usage; only solves the caching issue
    * Spinlock with Delay
        - Delay after lock release
        - while( (L == locked) || (test_and_set(L) == locked) )
            + while( L == locked );
            + delay( d[process_id] );
         - Only works with hardware cache coherence
        - Delay with exponential backoff
        - while( test_and_set(L) == locked )
            + delay(d);
            + d = d * 2;
        - Static delay: Delay based on a predetermined amount of time for each
        - Works even without hardware cache coherence
        process
        - Dynamic delay: Delay increases with successive failures to acquire
        - Dynamic delay means that when contention is low, delay will be short
        
    * Ticket Lock
        - Fairness: Determining which process gets the lock when it becomes
        available; should be the one waiting the longest
        - struct lock{ int next_ticket; int now_serving; };
        - acquire_lock(L):
            + int my_ticket = fetch_and_increment(L->next_ticket);
            + pause( my_ticket - L->now_serving );
            + if( L->now_serving == my_ticket ) { return; }
            + goto( pause );
        - release_lock(L):
            + L->now_serving++;
        - On release, if cache coherence is invalidate, there's still contention
        - If cache coherence is update, there's no contention
    * Spinlock Summary
        1. read and test_and_set (no fairness)
        2. test_and_set with delay (no fairness)
        3. ticket_lock (fair but noisy)
    * Array-based Queueing Lock
        - For each lock L: flags[N] (queue where N = number of processors)
            + Two states (has-lock (HL) and must-wait (MW))
            + Queue array is a circular buffer
        - For each lock L: queuelast = 0; (init)
            + Indicates the starting point of the queue
            + When you want to add yourself to the queue, you add yourself at
            position queuelast
        - lock(L):
            + myplace = fetch_and_increment(queuelast);
            + while( flags[myplace%N] == MW )
        - unlock(L):
            + flags[current%N] = MW;
            + flags[(current+1)%N] = HL;
        - Only one atomic operation (fetch_and_increment)
        - Fair: Next process in queue is guaranteed to get the lock
        - Unaffected by other processes acquiring/releasing lock
        - Cons:
            + Size of queue is as big as number of processors (N)
            + Still allocates this data structure Even if not all processors 
            will contend for lock (statically sized)
            + Still possible that more than one core is awoken; these memory
            locations may share the same cache line (false sharing)

| ![array](images/shm_array_queueing_lock.png) |
|:--:|
| Array-based Queueing Lock |

    * Linked List-based Queueing Lock
        - Mello-Crummy and Scott (MCS) queueing lock
        - One linked list for each lock (guarantees fairness)
        - struct q_node { bool got_it; q_node* next; };
        - lock(L,me):
            + join L; // atomic, point last_requester in head node to me, point
            "next" at end of queue to me
            + await precessor to signal; // spin
        - fetch_and_store(L,me): returns what was contained in L and stores me
        in L; use this to implement the join functionality
            + For simultaneous access, either thread can win
        - unlock(L,me):
            + remove me from L;
            + signal successor;
            + If there is no successor, set head node to null; this can cause a
            race condition if a new request is forming
        - To solve this race condition, use an atomic compare_and_swap when
        removing "me" from the list. comp_and_swap(L,me,null)
            + if( L == me ) { swap( me, null ); }
            + Returns true if swapped, false otherwise
            + If it returns false during unlock, wait until my next pointer is
            not null before finishing unlock
        - Pros:
            + Fair
            + Solves space complexity issue of array-based queueing lock
            (dynamic instead of static)
        - Cons:
            + Linked list maintainence introduces some overhead that isn't 
            present in the array-based version
            + Performance can decrease if the architecture doesn't implement the
            fancier atomic operations used

| ![linked_list](images/shm_linked_list_queueing_lock.png) |
|:--:|
| Linked List Queueing Lock |

    * Algorithm Grading
        - If processor provides a fetch_and_free operation, queueing locks are
        a good choice. If the processor only provides test_and_set, expontential
        backoff is a better choice.

| Algorithm        | Latency | Contention | Fair | Spin | RMW Ops/CS | Space | Signal one lock |
|------------------|:-------:|:----------:|:----:|:----:|:----------:|:-----:|:---------------:|
| Spin on T&S      | Low     | High       | No   | Shm  | High       | Low   | No              |
| Spin on read     | Low     | Med        | No   | Shm  | Med        | Low   | No              |
| Spin with delay  | Low     | Low        | No   | Shm  | Low        | Low   | No              |
| Ticket lock      | Low     | Low        | Yes  | Shm  | Low        | Low   | No              |
| Array Queue Lock | Low     | Low        | Yes  | Pvt  | 1          | High  | Yes             |
| LL Queue Lock    | Low     | Low        | Yes  | Pvt  | 1 (max 2)  | Med   | Yes             |

## Communication

    * Centralized (Counting) Barrier
        - Threads wait for all others to arrive at one point before proceeding
        - Count is initialized to N
        - When a thread arrives at the barrier, it atomically decrements and
        waits for the count to become 0
        - count = N; // init
        - atomic_decrement(count);
        - if(count == 0)
            + count = N;
        - else
            while(count > 0);
            while(count != N); // this fixes the issue cited below
        - Issue: Before the last processor sets count to N, other processors may
        race to the next barrier and proceed incorrectly
            + Need to wait for count to reset before proceeding
    * Sense Reversing Barrier
        - Goal is to eliminate the while(count > 0) spinning loop
        - Use a shared sense variable to indicate which side of the barrier 
        we're on
        - True indicates barrier hasn't happened yet, false indicates it has
        - count = N; // init
        - sense  true;
        - atomic_decrement(count);
        - if(count == 0)
            + count = N;
            + sense = false
        - else
            while(sense);
        - Issues: High contention on network for single shared "sense" variable
    * Tree Barrier
        - Build a tree of sense variables such that fewer processes are sharing
        the same variable
        - Once one barrier is met, move up the tree to the next barrier
        - When a processor arrives at a variable, it decrements the count
            + If 0, must recurse (repeat at the next level)
            + If 1, spin on the local locksense
        - When the last process reaches the root, it will flip the locksense flag
            + Then, recurse back down the tree, flipping locksense at each level
        - Issues
            1. locksense variable is dynamically determined by arrival pattern
            2. Lots of contention if number of processes is large
            3. If not cache coherent, the spin occurs on remote memory
        - Non-Uniform Memory Architecture (NUMA): Accessing local memory is 
        faster than accessing remote memory
            + Same as distributed shared memory architecture

| ![tree_barrier](images/shm_tree_barrier.png) |
|:--:|
| Tree Barrier |

    * MCS Tree Barrier (4-ary Arrival Tree)
        - Two data structures for each node
            + HC: Have children
            + CN: Child not ready (signal parent)
        - Chose 4 children for performance reasons (tested)
        - In a cache coherent multiprocessor, parent only has to spin on one 
        word (memory location)

| ![mcs_arrival](images/shm_mcs_barrier_arrival.png) |
|:--:|
| MCS Tree Barrier (4-ary Arrival) |

    * Binary Wakeup
        - One data structure
            + CP: Child pointer
        - Minimizes the path to furtherest child
        - Each parent is spinning on a statically determined location
        - Uses CP (child pointer) to signal child
        - Because everything is statically assigned, this solves the issue of
        accessing remote memory

| ![mcs_wakeup](images/shm_mcs_barrier_wakeup.png) |
|:--:|
| MCS Tree Barrier (Binary Wakeup) |

    * Tournament Barrier
        - N players, log2(N) rounds
        - This means there are only two "contestants" in each round
        - The "winner" is predetermined so the memory locations to reference are
        static (match fixing)
            + This is especially important in non-cache coherent architectures
        - When the winner finishes, it waits for the loser to finish
            + If it is already finished, it proceeds
        - When the entire tree is finished, the winner tells the loser
            + This process recurses back through the tree
        - Tree barrier vs Tournament barrier
            + Spin locations are statically determined in tournament barrier
            + Tournament barrier can be implemented with only atomic read/write;
            tree barrier requires fetch_and_free
            + Total amount of communication is the same: O(logN)
            + Tournament barrier works even in the absence of physical shared 
            memory (simply message passing)
        - MCS barrier vs Tournament barrier
            + Tournament can't exploit spatial locality; MCS takes advantage of
            children occupying the same cache line
            + Neither need fetch_and_free operation
            + Tournament barrier works even in the absence of physical shared 
            memory (simply message passing)

| ![tournament](images/shm_tournament_barrier.png) |
|:--:|
| Tournament Barrier |

    * Dissemination Barrier
        - Not pairwise communication, information diffusion
        - N doesn't need to be a power of 2
        - For each round(k) when N=5:
            + Pi sends a message to P(i+2^k)%N
            + For round 0: 0->1, 1->2, 2->3, 3->4, 4->0
            + For round 1: 0->2, 2->4, 4->1, 1->3, 3->0
            + For round 2: 0->4, 4->3, 3->2, 2->1, 1->0
            + For round 3: 0->3, 3->1, 1->4, 4->2, 2->0
            + O(N) communication events per round
        - ceil(log2(N)) rounds are required for barrier completion
            + Guarantees that every process has sent and received a message to
            every other process
        - No distinction between arrival and wakeup
        - Static determination of memory location
        - Pros:
            + No hierarchy
            + Works for NCC and clusters
            + Communication complexity is O(NlogN) versus O(logN) in MCS and
            tournament barriers
    * Performance Evaluation
        - Spin Algorithms
            + Spin on test_and_set
            + Spin on read
            + Spin with delay
            + Ticket lock
            + Array queue lock
            + List queue lock
        - Barrier Algorithms
            + Counter
            + Tree
            + MCS Tree
            + Tournament
            + Dissemination
        - Parallel Architectures
            + CC SMP
            + CC NUMA
            + NCC NUMA
            + MP Cluster
        - The best performance depends on the architecture; the only way to know
        is to implement and test
            + Trends are more important than absolute numbers as hardware changes

## Lightweight RPC

    * Remote Procedure Calls
        - RPC allows for a client/server architecture across address spaces
        - This provides safety between processes (one crashing won't crash the 
        other), but costs some performance, even on the same machine
    * RPC vs Local Procedure Call
        - In a local call, everything happens at compile time
        - RPC:
            1. Caller traps into kernel (call trap)
            2. Kernel validates call
            3. Kernel copies arguments into kernel buffers from client address 
            space
            4. Kernel locates server procedure
            5. Kernel copies arguments from kernel buffer to address space of
            the server
            6. Kernel schedules server to run the procedure
            7. When server is complete, it traps again (return trap)
            8. Kernel copies results from address space of server to kernel 
            buffers
            9. Kernel copies results from kernel buffers to client address space
            10. Kernel schedules client to continue running
        - RPC results in two traps and two context switches, plus one execution
            + This results in four copies between user/kernel address space
        - Ideally, we'd like to get the kernel out of the way
    * Copying Overhead
        - In each client/server or server/client switch, a total of four copies
        occur; two in the user address space and two in the kernel address space
    * Reducing RPC Binding Overhead
        - Set up (binding) is a one time cost -> one time cost
        - Server publishes a "procedure descriptor" that contains:
            + Entry point in server address space
            + Argument stack size
            + # of simultaneous calls it can support (multithreading)
        - At binding, kernel allocates a buffer of shared memory and maps it
        into the address space of both the client and server
            + The size is specified by the server (argument stack size)
            + After this mapping is complete, the server can get out of the way
            + Client gets a "binding object" that it can present to the kernel
            to verify it is authenticated to make remote calls on the server
        - Kernel mediation (binding) only happens at the first call
    * Reducing RPC Call Overhead
        - The client address space will copy arguments into the A-stack
            + Can only be done by value, not reference (local addresses will 
            have no meaning to the server)
        - Instead of copying all of the data, the kernel can borrow the client
        thread and doctor it to run on the server address space
            + Client is blocked after making the call
            + Execute the client thread in the address space of the server
            + Set program counter, address space descriptor, and stack
            + Kernel allocates an execution stack (E-stack) that the server can
            use to complete the RPC
            + Arguments/results are passed through the A-stack
        - This eliminates the serialization and two of the copies
            + Now, only one copy to marshal the data into the A-stack and one to
            unmarshal the data into the destination address space

| ![overhead](images/shm_copying_overhead.png) |
|:--:|
| Copying Overhead |

    * Reducing RPC Overhead Summary
        - Explicit costs: Call trap, switching domain to server address space, 
        return trap
        - Implicit costs: Loss of locality

| ![rpc_cheap](images/shm_reducing_overhead.png) |
|:--:|
| Making RPC Cheap |

    * RPC on SMP
        - Exploit multiple processors
            + Pre-load server domain in a particular processor (one CPU 
            dedicated to preserving the server's address space)
            + Keep caches warm
        - Can map the server to multiple CPUs to service more requests
        - Taken mechanism typically used for distributed systems and made it
        efficient for providing services locally
            + Provides safety through putting each service in its own protection
            domain

## Scheduling

    * How should the scheduler choose the next thread to execute?
        - FCFS: Most fair
        - Highest static priority: Give priority to most important
        - Highest dynamic priority: Give priority to I/O bound tasks
        - Memory contents in cache: Will have the best performance
    * Cache Affinity Scheduling
        - Two orders of magnitude between L1 cache and memory
        - Makes sense to schedule thread on the same processor after it's been
        descheduled because its contents might still be in cache
            + However, if another thread was scheduled in between, the original
            thread's contents won't be in cache
    * Scheduling Policies
        - FCFS: Pick the thread that entered the runnable queue first
            + Ignores affinity for fairness
        - Fixed processor: Ti will always run on the same processor
            + Initial processor choice may depend on load balance
        - Last processor: Ti will always run on the same processor as it ran on
        previously
            + If there's no previous thread, it will still pick something
        - Minimum intervening: Pick the processor with highest affinity for Ti
            + Requires keeping track of the most data 
    * Minimum Intervening Policy
        - Calculate an affinity index for each thread for all processors
        - Track the affinity for thread Ti across all processors
        - Provides the best chance that its memory contents will be in cache
        - This can be prohibitively espensive for many threads/processors
            + Limited MI: Only keep affinity index for the top N processors
        - Smaller index == Higher affinity
    * Minimum Intervening Plus Queue Policy
        - Keep a queue of threads for each processor
        - Then, if the queue is long, reschedule the thread elsewhere
            + If time spent in queue > time to reload data from memory
            + The threads ahead in the queue will also pollute the cache, so the
            affinity will be lower when Ti actually runs
    * Summarizing Scheduling Policies
        - FCFS: Ignores affinity for fairness
        - Fixed processor: Ti always on Pfixed (focus on affinity)
        - Last processor: Ti on Plast (focus on affinity)
        - Minimum intervening: Ti -> Pj(min(I)) (focus on cache pollution)
        - MI plus queue: Ti -> Pj(min(I+Q)) (focus on cache pollution)
        - Fixed/last processor are thread centric
        - MI/MI plus queue are processor centric
    * Implementation Issues
        - Queue-based
            + Global queue of threads to be run (makes logical sense for FCFS)
            + Affinity-based local queues (one per process, depends on specific
            policy)
            + In affinity-based, if one processors queue is empty, it might take
            work from another "work stealing"
        - Priority queue
            + Ti's priority = base priority + age + affinity
            + This determines the position in the queue
    * Performance
        - Figures of Merit
            + Throughput: How many threads get executed per unit time
            + Response time: How long does a thread take to complete
            + Variance: How much does the completion time vary 
            + Throughput is system-centric, response time and variance are user-
            centric metrics
        - Time to reload cache increases with memory footprint
            + Indicates that cache affinity is important
            + However, under heavy load, a fixed processor strategy might give
            better performance due to cache pollution
        - Procrastination: processor idles when its queue is empty before 
        stealing work from another queue
            + If a thread enters the queue during the idle time, it will have 
            better affinity than the thread stolen from another queue

| ![footprint](images/shm_memory_vs_cache_reload.png) |
|:--:|
| Memory Footprint vs Cache Reload Time |

    * Cache Affinity and Multicore
        - Processors have multiple cores and are hardware multithreaded
        - HW multithreaded: If a thread that is currently running experiences a
        long latency operation (I/O), hardware can switch among threads without
        any intervention from the OS
        + L1 cache is local to each core, L2 cache is shared
        - Scheduler maps threads onto threads available in hardware
            + Try to map threads to cores that have the required data in the
            local L1 cache
    * Cache Aware Scheduling
        - Cache frugal threads - Cft
        - Cache hungry threads - Cht
        - Schedule some cache-frugal and some cache-hungry threads on each core
            + Goal is that total size of cache need is less than the size of the
            last level cache (LLC)
            + sum( Cft ) + sum( Cht ) < size( LLC )
        - Only way to discern this is to profile the performance of these
        threads over time
            + Overhead of information gathering needs to be kept to a minimum
        - Processor scheduling is NP-complete (requires heuristics)

## Parallel OS Case Studies

    * OS Challenges for Parallel Machines
        - Size bloat: Additional features causing system software bottlenecks 
        for global data structures
        - Memory latency is large
        - NUMA effects: Multiple nodes with a processor and memory; a CPU may 
        need to access memory through the "network" on another CPU
        - Deep memory heirarchy: 3 levels of cache before memory
        - False sharing: Two pieces of memory on the same cache line but
        otherwise aren't connected
        - Modern processors employ larger cache blocks causing more false sharing
    * OS Design Principles for Parallel Machines
        - Cache conscious decisions: Pay attention to locality and exploit cache
        affinity in scheduling decisions
        - Limit shared system data structures
        - Keep memory accesses local to the memory associated with the CPU
    * Page Fault Service
        - CPU accesses a page
            + TLB lookup
            + Page table lookup
        - If TLB and page table lookup missed, go to disk
            + Locate file
            + Allocate a physical page frame (page replacement) and move data
            + Update page table (VPN and PFN)
            + Update TLB (VPN and PFN)
        - Page frame service complete
        - Allocating a page frame and updating the page table must occur in
        serial; the rest can be done in parallel
    * Parallel OS and Page Fault Service
        - Easy scenario: Multiprocess workload (threads running on different
        processors, but totally independent)
            + Page table distinct (one per node)
            + No serialization
        - Hard scenario: Multithreaded workload (process with multiple threads
        in a shared address space)
            + Multiple threads mapped to the same node; sharing may induce
            serialization
            + Page table shared across threads
            + Shared entries in processor TLBs
    * Recipe for Scalable Structure in Parallel OS
        - For every subsystem:
            1. Determine the functional needs of that service
            2. To ensure concurrent execution of service, minimize shared data
            structures (less sharing -> more scalable)
            3. Where possible, replicate/partition system data structures. This
            allows for less locking and more concurrency
    * Tornado;s Secret Sauce
        - Clustered object: Illusion of a single object to the nodes. Under the
        hood, there are multiple replicated representations
        - To what degree is there replication (clustering)?
            + Choice of implementor of service
            + Singleton representation, one per core, one per CPU, one per group
            of CPUs, ...
            + Protected procedure call (PPC) to maintain consistency
    * Traditional Structure
        - PCB: Process control block, process-specific data
        - TLB: Translation lookaside buffer
        - PT: Page table
        - Virtual pages on disk
        - Each of these is per process

| ![traditional](images/shm_traditional_structure.png) |
|:--:|
| Traditional Virtual Memory Subsystem Structure |

    * Objectization of Memory Management
        - Divide the address space into regions that are all part of the OS page
        table (partition the page table)
        - Add a file cache manager (FCM) for each region to support the back end
        interaction with the disk
        - Page frame manager: DRAM object (moves the FCM from disk to memory)
        - Page I/O: Cached obect representation (COR)
    * Objectized Structure of VM Manager
        - Process object: Mostly read only, replicate one per CPU
        - Region object: Critical path of page fault, one per group of processors
        - FCM object: Partitioned representation for each region
        - COR object: Deals with physical entities (I/O) singleton object
        - DSM object: Break up physical memory into portions managed 
        individually by each processor

| ![vmmanager](images/shm_vm_manager.png) |
|:--:|
| Objectized Structure of Virtual Memory Manager |

    * Advantages of Clustered Object
        - Same object reference on all nodes
        - Allows incremental optimization "under the covers"
            + Usage pattern determines level of replication
        - Less locking
        - Page fault handling scales with number of processors
        - Destruction of a region may take more time (deleting each of the 
        representations)
            + Expect region destructions to be less frequent than handling page
            faults (optimized for the common case)
    * Implementation of Clustered Object
        - Translation table: Maps object reference to a representation in memory
        - If an object hasn't been referenced yet, no reference will exist
            + Miss in translation table goes to object miss handler table
        - Miss handler table
            + Partitioned data structure containing mapping between object
            references and the corresponding miss handlers
            + Object miss handler will install a mapping between the object 
            reference and the representation
        - Global miss handler
            + If miss handler table doesn't have the miss handler for this 
            particular object reference, go to the global miss handler
            + Global miss handler resolves location of object miss handler
            + Replicated on every node
            + Aware of how the miss handling table has been partitioned and 
            distributed across nodes
    * Non Hierarchical Locking and Existence Guarantee
        - Hierarchical locking kills concurrency
            + lock(process)
            + lock(region)
            + lock(FCM)
            + lock(COR)
        - Only need to lock objects on the same path
        - Process object could be migrated; can't do this while a descendent is
        locked
        - Add a reference count to guarantee existence instead of hierarchical
        locking
            + When a descendent is locked, increase the reference count of the
            parent objects (if a region is locked, increase the reference count
            of the process object)
            + This guarantees that the process object won't be load balanced
            elsewhere
        - Provides the existence guarantee of hierarchical locking without
        losing concurrency
        - Locks are limited to a particular replica, not all replicas
    * Dynamic Memory Allocation
        - Break up heap; put into physical portion of memory close to node N1 or
        N2
        - Dynamic memory requests from threads on N1 or N2 are satisfied by the
        partition of the heap in nearby memory

| ![dynamic_memory](images/shm_dynamic_memory.png) |
|:--:|
| Dynamic Memory Allocation |

    * Inter-Process Communication
        - Microkernel, not monolithic; need to communicate across processes
        - Object calls need IPC; realized by protected procedure calls 
            + Local PPC: No context switch
            + Remote PPC: Full context switch
        - Similar to LRPC
        - Clustered object implementation must keep objects consistent using PPC
        - This is all managed in software; can't use hardware cache coherence 
        (replicas are only a concept to the OS, not hardware)
    * Tornado Summary
        - Object oriented design for scalability
        - Multiple implementations of OS objects
            + Can change as performance requirements change
        - Optimize for common case
            + Page fault handling vs region destruction
        - No hierarchical locking
        - Limited sharing of OS data structures
    * Summary of Ideas in Corey System
        - Limit sharing of kernel data structures
        - Address ranges specified per application
            + Thread tells the OS what range it will run in
            + Similar to region concept in Tornado
        - Shares: Application thread can specify that a system facility it's 
        using is private (not shared among other threads)
        - Dedicated cores for kernel activity
            + Locality of kernel data structures can be pinned to specific cores
            so there's no need to move them
        - Reduce latency due to communication across cores
    * Virtualization
        - Would need to rewrite the operating system for every new parallel
        architecture
        - Cellular Disco combines the ideas of virtualization and the needs for
        scalability of parallel operating systems
        - Cellular Disco layer manages hardware resources (CPU, I/O, drivers)
        - Cellular Disco serves as a virtualization layer
        - Cellular Disco uses "trap and emulate" strategy
            + On an I/O request, Cellular Disco issues the request from the 
            guest OS through the host OS to the hardware
            + When the interrupt occurs with the response, the interrupt goes
            straight to the VMM layer
            + Therefore, no need to change host OS for different hardware
        - Shows by construction that a virtual machine monitor can manage the 
        resources of a multiprocessor as well as a native operating system
            + Overhead of providing these services through the virtualization
            layer is small (<10%)
        - Cellular Disco runs as a multithreaded kernel process
        
| ![disco](images/shm_cellular_disco.png) |
|:--:|
| Cellular Disco |
