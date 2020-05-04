package org.iot.devicefactory.util

import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Sensor

class LibraryUtils {
	
	static def BaseSensor asBaseSensor(Sensor sensor) {
		switch sensor {
			BaseSensor: sensor
			OverrideSensor: sensor.parent.asBaseSensor
		}
	}
}