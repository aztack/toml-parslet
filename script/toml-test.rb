# borrowed from https://gist.github.com/cespare/5052442
require "toml-parslet"
require "json"

raw = ARGF.read
begin
  decoded = TOML.load(raw)
rescue => e
  STDERR.puts e.inspect
  exit 1
end

def transform_toml(t)
  t.reduce({}) do |j, (k, v)|
    j.merge k => transform_toml_value(v)
  end
end

def transform_toml_value(v)
  type, value = case v
  when String then ["string", v]
  when Fixnum, Bignum then ["integer", v.to_s]
  when Float then ["float", v.to_s]
  when Time, DateTime then ["datetime", v.strftime("%Y-%m-%dT%H:%M:%SZ")]
  when TrueClass, FalseClass then ["bool", v.to_s]
  when Array then ["array", v.map { |e| transform_toml_value(e) }]
  when Hash
    return transform_toml(v)
  else raise "Unhandled type: #{v.class}"
  end
  { "type" => type, "value" => value }
end

puts transform_toml(decoded).to_json
