# gofence-profiling

See this post for more background: 

Implementation at https://github.com/buckhx/gofence

The benchmarks were ran between two Digital Ocean droplets in the same data center with private networking enabled
The bodies.lua script cycles through requests.geo.jsonl composed of ~1k MTA buses are used to emulate taxis and 10k+ tweets emulate ride requests.
The fences are based on NYC 2010 Census Tracts. All data is in /nyc

@gofence
* 1 Intel(R) Xeon(R) CPU E5-2620 0 @ 2.00GHz
* Ubuntu 15.04
* fence v0.0.4
* go 1.6
* wrk 4.0.0
* Private Networking - NYC3

@wrkr
* 1 Intel(R) Xeon(R) CPU E5-2620 0 @ 2.00GHz
* Ubuntu 15.04
* wrk 4.0.0
* Private Networking - NYC3

iperf stats
```
------------------------------------------------------------
Client connecting to gofence, TCP port 5001
TCP window size: 85.0 KByte (default)
------------------------------------------------------------
[  3] local @wrkr port 33766 connected with @gofence port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec  1.06 GBytes   908 Mbits/sec
```

This is a baseline benchmark. /engarde returns a text string.

```
@gofence$ ./fence .
@wrkr$ wrk -t 1 -c 50 -d 1m http://gofence:8080/engarde
Running 1m test @ http://gofence:8080/engarde
  1 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     5.62ms    5.80ms  63.95ms   90.98%
    Req/Sec    10.93k     3.49k   18.83k    63.83%
  653410 requests in 1.00m, 93.47MB read
Requests/sec:  10873.85
Transfer/sec:      1.56MB
```

Brute force

```
@gofence$ ./fence --fence brute .
@wrkr$ wrk -t 1 -c 50 -d 5m -s scripts/bodies.lua http://gofence:8080/fence/nyc-census-2010-tracts/search
Let 37290 bodies hit the floor
Let 37290 bodies hit the floor
Running 5m test @ http://gofence:8080/fence/nyc-census-2010-tracts/search
  1 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    36.12ms   13.08ms 193.37ms   75.62%
    Req/Sec     1.40k   317.10     1.82k    78.62%
  417144 requests in 5.00m, 248.02MB read
  Non-2xx or 3xx responses: 11
Requests/sec:   1390.04
Transfer/sec:    846.32KB
```

City is composed of an NYC burrough

```
@gofence$ ./fence --fence city .
@wrkr$ wrk -t 1 -c 50 -d 5m -s scripts/bodies.lua http://gofence:8080/fence/nyc-census-2010-tracts/search
Let 37290 bodies hit the floor
Let 37290 bodies hit the floor
Running 5m test @ http://gofence:8080/fence/nyc-census-2010-tracts/search
  1 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    15.96ms    9.99ms 107.30ms   72.54%
    Req/Sec     3.28k     0.87k    4.88k    59.57%
  979162 requests in 5.00m, 582.17MB read
  Non-2xx or 3xx responses: 26
Requests/sec:   3262.88
Transfer/sec:      1.94MB
```

Rtree

```
@gofence$ ./fence --fence rtree .
@wrkr$ wrk -t 1 -c 50 -d 5m -s scripts/bodies.lua http://gofence:8080/fence/nyc-census-2010-tracts/search
Let 37290 bodies hit the floor
Let 37290 bodies hit the floor
Running 5m test @ http://gofence:8080/fence/nyc-census-2010-tracts/search
  1 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    14.01ms   16.82ms 185.69ms   89.68%
    Req/Sec     4.95k     1.85k    8.13k    61.62%
  1477798 requests in 5.00m, 0.86GB read
  Non-2xx or 3xx responses: 39
Requests/sec:   4925.22
Transfer/sec:      2.93MB
```

S2 at level 16. Takes a minute to build all the cells.

```
@gofence$ ./fence --fence s2 -z 16 .
@wrkr$ wrk --latency -t 1 -c 50 -d 5m -s scripts/bodies.lua http://gofence:8080/fence/nyc-census-2010-tracts/search
Let 37290 bodies hit the floor
Let 37290 bodies hit the floor
Running 5m test @ http://gofence:8080/fence/nyc-census-2010-tracts/search
  1 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    10.51ms    8.62ms  84.00ms   81.33%
    Req/Sec     5.46k     1.10k    7.81k    72.71%
  Latency Distribution
     50%    8.39ms
     75%   12.28ms
     90%   22.37ms
     99%   39.92ms
  1629003 requests in 5.00m, 0.95GB read
  Non-2xx or 3xx responses: 43
Requests/sec:   5429.64
Transfer/sec:      3.23MB
```

Get requests are faster b/c it doesn't need to use json.Unmarshal.

```
@gofence$ ./fence --fence s2 -z 16 .
@wrkr$ wrk -t 1 -c 50 -d 10s "http://gofence:8080/fence/nyc-census-2010-tracts/search?lat=40.7732&lon=-73.9641&key=old%20whitney"
Running 10s test @ http://gofence:8080/fence/nyc-census-2010-tracts/search?lat=40.7732&lon=-73.9641&key=old%20whitney
  1 threads and 50 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    10.75ms   14.00ms 109.28ms   88.65%
    Req/Sec     7.27k     2.26k   10.20k    61.00%
  72332 requests in 10.01s, 37.25MB read
Requests/sec:   7226.01
Transfer/sec:      3.72MB
```
