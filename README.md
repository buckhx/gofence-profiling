# gofence-profiling

See this post for more background: 

Implementation at https://github.com/buckhx/gofence

The benchmarks were ran between two Digital Ocean droplets in the same data center with private networking enabled
The bodies.lua script cycles through requests.geo.jsonl composed of ~1k MTA buses are used to emulate taxis and 10k+ tweets emulate ride requests.
The fences are based on NYC 2010 Census Tracts. All data is in [nyc](nyc)

Profiling graphs generated from pprof are ran using the --profile flag to mount the /pprof/debug endpoints while being loaded with traffic from a seperate droplet. They and can be found in the [pprof directory](pprof).

The binary used for these benchmarks is included in this repo

## Setup

@gofence
* 1 Intel(R) Xeon(R) CPU E5-2620 0 @ 2.00GHz
* Ubuntu 15.04
* fence v0.0.4
* go 1.6
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
## Profiling

These are the stats taken from pprof while being loaded from a wrk on a seperate droplet.

| Fence     | Ratio  | fence.Get | json.Marshal | json.Unmarshal | http.readReqest | http.finishRequest | runtime.gcBgMarkWorker | Total | Other |
|-----------|-------:|----------:|-------------:|---------------:|----------------:|-------------------:|-----------------------:|------:|------:|
| brute     | 73.55% |     22.02 |         1.67 |           1.54 |            1.06 |               1.60 |                   1.11 | 29.94 |  0.94 |
| city      | 37.49% |     11.15 |         3.84 |           3.31 |            2.77 |               3.63 |                   2.84 | 29.74 |  2.20 |
| bbox      | 30.35% |      9.04 |         3.87 |           4.29 |            3.12 |               4.08 |                   2.93 | 29.97 |  2.64 |
| city_bbox | 12.88% |      3.70 |         4.93 |           4.43 |            3.50 |               5.02 |                   3.92 | 28.72 |  3.22 |
| qtree_z14 |  6.66% |      1.98 |         5.95 |           4.97 |            3.78 |               5.29 |                   4.60 | 29.74 |  3.17 |
| rtree     |  5.68% |      1.70 |         5.85 |           5.25 |            3.60 |               5.75 |                   4.57 | 29.92 |  3.20 |
| s2_z16    |  2.99% |      0.89 |         6.97 |           5.16 |            4.78 |               5.98 |                   2.88 | 29.73 |  3.07 |


![chart link broken](https://docs.google.com/spreadsheets/d/1PYoxb7nhPA_zrh9oPFnUH0mvo8geYvEkjfe8Jtc0vvY/pubchart?oid=1153428443&format=image)

[interactive link](https://docs.google.com/spreadsheets/d/1PYoxb7nhPA_zrh9oPFnUH0mvo8geYvEkjfe8Jtc0vvY/pubchart?oid=1153428443&format=interactive)


## HTTP Benchmarking

THe HTTP Benchmarking was done using wrk on a single thread with 50 connections over 5 minutes

### Requests / Second

| Fence | Avg  | Max  | StDev | StDev (+/-) |
|-------|-----:|-----:|------:|------------:|
| brute | 1390 | 1820 |   317 |      78.62% |
| city  | 3262 | 4880 |   870 |      59.57% |
| rtree | 4925 | 8130 |  1850 |      61.62% |
| s2    | 5429 | 7810 |  1100 |      72.71% |

### Latency

| Fence | Avg   | Max    | StDev | StDev (+/-) |
|-------|------:|-------:|------:|------------:|
| brute | 36.12 | 193.37 | 13.08 |      75.62% |
| city  | 15.96 | 107.30 |  9.99 |      72.54% |
| rtree | 14.01 | 185.69 | 16.82 |      89.68% |
| s2    | 10.51 |  84.00 |  8.62 |      81.33% |

![chart link broken](https://docs.google.com/spreadsheets/d/1PYoxb7nhPA_zrh9oPFnUH0mvo8geYvEkjfe8Jtc0vvY/pubchart?oid=2000899835&format=image)

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
