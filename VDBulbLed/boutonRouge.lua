local BulbID = fibaro:get(fibaro:getSelfId(), "IPAddress")
HC2 = Net.FHttp("127.0.0.1", 11111)
jtable = '{"properties":{"parameters":[{"id":38,"size":4,"value":17},{"id":37,"size":4,"value":1107296510}]}}'
HC2:PUT("/api/devices/".. BulbID,jtable)
