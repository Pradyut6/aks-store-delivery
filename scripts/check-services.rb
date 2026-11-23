require 'yaml'

resources = YAML.load_stream(File.read(ARGV.fetch(0))).compact
services = resources.select { |resource| resource.fetch('kind') == 'Service' }

%w[store-front store-admin].each do |name|
  service = services.find { |resource| resource.dig('metadata', 'name') == name }
  abort "Missing internal service #{name}" unless service&.dig('spec', 'type') == 'ClusterIP'
end

services.each do |service|
  spec = service.fetch('spec')
  if %w[LoadBalancer NodePort].include?(spec['type']) || spec.fetch('externalIPs', []).any?
    abort "Exposed service #{service.dig('metadata', 'name')}"
  end
end

workloads = resources.select { |resource| %w[Deployment StatefulSet].include?(resource.fetch('kind')) }
workloads.each do |workload|
  name = workload.dig('metadata', 'name')
  spec = workload.fetch('spec')
  abort "Service account token mounted by #{name}" unless spec.dig('template', 'spec', 'automountServiceAccountToken') == false
  if %w[virtual-worker virtual-customer].include?(name) && spec.fetch('replicas') != 0
    abort "Simulator enabled by default: #{name}"
  end
end
