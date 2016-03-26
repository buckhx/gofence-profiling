#! /bin/bash
[ -z "$MTA_API_KEY" ] && { echo "Need to set MTA_API_KEY"; exit 1; }
[ -z `type -P jq` ] && { echo "Need to install jq"; exit 1; }
curl -s "http://api.prod.obanyc.com/api/siri/vehicle-monitoring.json?key=$MTA_API_KEY&version=2&VehicleMonitoringDetailLevel=basic" |
jq -c '.Siri.ServiceDelivery.VehicleMonitoringDelivery[0].VehicleActivity[] |
.MonitoredVehicleJourney as $v | {type: "Feature", properties: {line:$v.LineRef, vehicle: $v.VehicleRef, bearing: $v.Bearing, ts: .RecordedAtTime}, geometry: { type: "Point", coordinates: [$v.VehicleLocation.Longitude, $v.VehicleLocation.Latitude]}}'
