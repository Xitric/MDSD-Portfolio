package org.iot.devicefactory.util

import java.util.ArrayList
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.deviceLibrary.BaseSensor
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.OverrideSensor
import org.iot.devicefactory.deviceLibrary.Sensor

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.CommonUtils.*

class DeviceLibraryUtils {

	static def getAllHierarchySensors(Board board) {
		val allSensors = board.boardHierarchy.flatMap[sensors]
		allSensors.filter [ sensor |
			!allSensors.takeWhile[it !== sensor].exists[name == sensor.name]
		]
	}

	static def getBoardHierarchy(Board board) {
		val hierarchy = new ArrayList<Board>()
		var current = board
		while (current !== null) {
			hierarchy.add(current)
			current = current.parent
		}
		return hierarchy
	}

	static def getParentSensor(Sensor sensor) {
		val board = sensor.getContainerOfType(Board)
		board.parent.allHierarchySensors.findFirst[name == sensor.name]
	}
	
	static def Iterable<Variable> getInternalVariables(Sensor sensor) {
		switch sensor {
			BaseSensor:
				sensor.input?.variables?.variables ?: emptyList
			OverrideSensor: {
				val parentSensor = sensor.parentSensor
				if (parentSensor === null) {
					return emptyList
				} else {
					parentSensor.variables
				}
			}
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
