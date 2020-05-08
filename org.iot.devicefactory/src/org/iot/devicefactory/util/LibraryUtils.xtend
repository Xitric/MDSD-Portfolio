package org.iot.devicefactory.util

import java.util.HashSet
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.Sensor

import static extension org.eclipse.xtext.EcoreUtil2.*

class LibraryUtils {

	static def getAllHierarchySensors(Board board) {
		board.boardHierarchy.flatMap[sensors]
	}

	static def getBoardHierarchy(Board board) {
		val hierarchy = new HashSet<Board>()
		var current = board
		while (current !== null) {
			hierarchy.add(current)
			current = current.parent
		}
		return hierarchy
	}
	
	static def getParentSensor(Sensor sensor) {
		val board = sensor.getContainerOfType(Board)
		board.boardHierarchy.findFirst[name == sensor.name]
	}
}
