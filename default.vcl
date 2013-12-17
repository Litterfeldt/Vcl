backend vendre {
  .host = "www.vendre.se";
  .port = "80";
}
sub vcl_recv {
  if (req.request != "GET" &&
      req.request != "HEAD" &&
      req.request != "PUT" &&
      req.request != "POST" &&
      req.request != "TRACE" &&
      req.request != "OPTIONS" &&
      req.request != "DELETE") {
        return (pipe);
      }

  if (req.request == "POST") {
    return (pass);
  }
  if (req.request != "GET" && req.request != "HEAD") {
    return (pass);
  }
  if (req.http.Authorization) {
    return (pass);
  }
  if (req.http.host == "www.vendre.se" ||
      req.http.host == "vendre.se" ||
      req.http.host == "cache.testavendre.se") {
    remove req.http.Cookie;
    set req.http.host = "vendre.se";
    set req.backend = vendre;
  }
  if (req.backend.healthy) {
    set req.grace = 60s;
  } else {
    set req.grace = 1d;
  }

  return (lookup);
}

sub vcl_deliver {
  # Add a header to indicate a cache HIT/MISS
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }
  return (deliver);
}

sub vcl_fetch {
  if (req.http.host == "www.vendre.se" ||
    req.http.host == "vendre.se" ||
    req.http.host == "cache.testavendre.se") {
      set beresp.ttl = 1d;
  }
  set beresp.grace = 1d;
}
