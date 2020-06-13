# IoT Device Factory
This repository contains the source code for a project written in Xtext and Xtend. It describes a DSL for developing sensor sampling code for the Internet of Things. To do so, the user must first specify the anatomy of their IoT devices using an `.iotc` file:

`/lib/boards/library.iotc`
```
package lib.boards

define board Esp
	sensor motion i2c(0x5F) as (x, y, z)

	sensor luminance pin(12) as l

define board Esp32 includes Esp
	sensor thermometer i2c(0x6E) as (t, l)

define board Esp8266 includes Esp
	override sensor motion
		preprocess map[(x * 1.2, y * 1.1, z * 1.3) => (x, y, z)]

define board Esp32_azure includes Esp32, Esp8266
	override sensor Esp32.motion
```

The user can then import this device library into an `.iot` DSL document where the deployment is described:

`/deployment.iot`
```
library lib.boards.*

language python

channel endpoint

abstract device controller board Esp32_azure
	in endpoint

	sensor luminance sample signal
		data status
			out endpoint filter[l > 10]
				.map["Light" => s]

device child_controller includes controller
	override sensor luminance sample frequency 10
		data raw_light
			out endpoint

	sensor motion sample signal
		data avg_motion
			out endpoint map[x + y + z => acc]
				.window[10].mean

cloud
	transformation raw_light as x
		data is_dark
			out window[5].max
				.filter[x < 10]
```

The result will be a set of MicroPython files ready to be deployed on IoT devices.
