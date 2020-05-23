package org.iot.devicefactory.util

import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.deviceLibrary.SensorDefinition
import org.iot.devicefactory.deviceLibrary.SensorInput

import static extension org.iot.devicefactory.util.CommonUtils.*

class DeviceLibraryUtils {

	static def String getName(SensorDefinition sensor) {
		switch sensor {
			BaseSensorDefinition: sensor.name
			OverrideSensorDefinition: sensor.parent.name
		}
	}
	
	static def SensorInput getInput(SensorDefinition sensor) {
		switch sensor {
			BaseSensorDefinition: sensor.input
			OverrideSensorDefinition: sensor.parent.input
		}
	}
	
	static def Iterable<Variable> getInternalVariables(SensorDefinition sensor) {
		switch sensor {
			BaseSensorDefinition:
				sensor.input?.variables?.variables ?: emptyList
			OverrideSensorDefinition:
				sensor.parent?.variables ?: emptyList
		}
	}
	
	static def Iterable<Variable> getVariables(SensorDefinition sensor) {
		val pipelineVars = sensor.preprocess?.pipeline?.variables
		if (pipelineVars.nullOrEmpty) {
			sensor.internalVariables
		} else {
			pipelineVars
		}
	}
}
