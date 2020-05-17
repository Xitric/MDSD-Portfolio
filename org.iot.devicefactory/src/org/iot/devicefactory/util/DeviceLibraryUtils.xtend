package org.iot.devicefactory.util

import java.util.ArrayList
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Sensor

import static extension org.iot.devicefactory.util.CommonUtils.*

class DeviceLibraryUtils {

	static def getBoardHierarchy(Board board) {
		val hierarchy = new ArrayList<Board>()
		var current = board
		while (current !== null) {
			hierarchy.add(current)
			current = current.parent
		}
		return hierarchy
	}

	static def String getName(Sensor sensor) {
		switch sensor {
			BaseSensor: sensor.name
			OverrideSensor: sensor.parent.name
		}
	}
	
	static def Iterable<Variable> getInternalVariables(Sensor sensor) {
		switch sensor {
			BaseSensor:
				sensor.input?.variables?.variables ?: emptyList
			OverrideSensor:
				sensor.parent?.variables ?: emptyList
		}
	}
	
	static def Iterable<Variable> getVariables(Sensor sensor) {
		val pipelineVars = sensor.preprocess?.pipeline?.variables
		if (pipelineVars.nullOrEmpty) {
			sensor.internalVariables
		} else {
			pipelineVars
		}
	}
}
