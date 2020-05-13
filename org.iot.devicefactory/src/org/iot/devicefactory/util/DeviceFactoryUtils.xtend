package org.iot.devicefactory.util

import java.util.ArrayList
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.deviceFactory.BaseDevice
import org.iot.devicefactory.deviceFactory.ChildDevice
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.Sensor

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*

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

	static def getBoard(Device device) {
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
	
	static def Iterable<Variable> getVariables(Sensor sensor) {
		sensor.definition.variables
	}
}
