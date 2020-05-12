package org.iot.devicefactory.util

import java.util.ArrayList
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.QualifiedName
import org.iot.devicefactory.deviceFactory.BaseDevice
import org.iot.devicefactory.deviceFactory.ChildDevice
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.Sensor

import static extension org.eclipse.xtext.EcoreUtil2.*

class DeviceFactoryUtils {

	static def getDeviceHierarchy(Device device) {
		val hierarchy = new ArrayList<Device>()
		var current = device
		while (current !== null) {
			hierarchy.add(current)
			current = switch current {
				BaseDevice: null
				ChildDevice: current.parent
			}
		}
		return hierarchy
	}

	static def getSensorHierarchy(Sensor sensor) {
		sensor.getContainerOfType(Device).deviceHierarchy.flatMap[sensors].filter [
			definition === sensor.definition
		]
	}

	static def getBoard(EObject context) {
		val device = context.getContainerOfType(Device)
		val top = device.deviceHierarchy.last
		switch top {
			BaseDevice: top.board
			ChildDevice: null
		}
	}

	static def getBaseData(Data data) {
		val sensorHierachy = data.getContainerOfType(Sensor).sensorHierarchy
		sensorHierachy.findLast [
			datas.exists[name == data.name]
		].datas.findFirst[name == data.name]
	}

	static def matches(QualifiedName me, QualifiedName other) {
		val meSkipped = me.lastSegment == "*" ? me.skipLast(1) : me

		if (meSkipped.segmentCount > other.segmentCount) {
			return false
		}

		for (var i = 0; i < meSkipped.segmentCount; i++) {
			if (meSkipped.getSegment(i) != other.getSegment(i)) {
				return false
			}
		}

		return true
	}
}
