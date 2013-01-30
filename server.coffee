cluster = require("cluster")
http = require("http")
numCPUs = require("os").cpus().length
RedisStore = require("socket.io/lib/stores/redis")
redis = require("socket.io/node_modules/redis")
pub = redis.createClient()
sub = redis.createClient()
client = redis.createClient()
if cluster.isMaster
  i = 0
  while i < numCPUs
    cluster.fork()
    i++
  cluster.on 'fork', (worker) ->
    console.log 'forked worker ' + worker.process.pid
  cluster.on "listening", (worker, address) ->
    console.log "worker " + worker.process.pid + " is now connected to " + address.address + ":" + address.port    
  cluster.on "exit", (worker, code, signal) ->
    console.log "worker " + worker.process.pid + " died"
else
  app = require("express")()
  server = require("http").createServer(app)
  io = require("socket.io").listen(server)
  io.set "store", new RedisStore(
    redisPub: pub
    redisSub: sub
    redisClient: client
  )
  server.listen 8000
  app.get "/", (req, res) ->
    res.sendfile(__dirname + '/index.html');
  io.sockets.on "connection", (socket) ->
    console.log 'socket call handled by worker with pid ' + process.pid
    socket.emit "news",
      hello: "world"