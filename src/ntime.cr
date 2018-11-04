require "./ntime/*"
require "crest"
require "json"

class Task
  JSON.mapping(
    taskId: Int32
  )
end

def to_time_span(value : JSON::Any)
  Time::Span.new(0, value.as_i, 0)
end

today = Time.now.to_s("%F") # Date in ISO8601

request1 = Crest.post("http://192.168.1.200:8091/api/login", payload: "{\"username\":\"#{ENV["user"]}\",\"pwd\":\"#{ENV["pwd"]}\"}")

request2 = Crest.get("http://192.168.1.200:8091/api/results", params: {"from" => today, "to" => today}, cookies: request1.cookies)
request3 = Crest.get("http://192.168.1.200:8091/api/clockings", params: {"date" => today}, cookies: request1.cookies)

sleep 0.07

request4 = Crest.get("http://192.168.1.200:8091/api/async/response", params: {"taskid" => Task.from_json(request2.body).taskId}, cookies: request2.cookies)
request5 = Crest.get("http://192.168.1.200:8091/api/async/response", params: {"taskid" => Task.from_json(request3.body).taskId}, cookies: request3.cookies)

last_clocking = JSON.parse(request5.body)["clockings"].as_a.last
results = JSON.parse(request4.body)["results"][0]["minutesTypes"]
              .as_a
              .select { |item| item["name"] == "Aritmetico" }
              .map { |item| item["results"] }
              .first

puts "Saldo diario acumulado: #{to_time_span(results[0]["values"][1]["value"])}h"
puts "Saldo mensual acumulado: #{to_time_span(results[1]["values"][1]["value"])}h"
puts "Saldo anual acumulado: #{to_time_span(results[2]["values"][1]["value"])}h"
puts "Días de vacaciones utilizados: #{results[3]["values"][1]["value"].as_i}"
puts "Último movimiento: #{Time.parse_local(last_clocking["date"].to_s, "%FT%T")} (#{last_clocking["status"]["desc"]})"
