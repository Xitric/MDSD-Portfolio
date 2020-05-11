package org.iot.devicefactory.util

import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.Sensor

import static extension org.eclipse.xtext.EcoreUtil2.*
import java.util.ArrayList

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
}
