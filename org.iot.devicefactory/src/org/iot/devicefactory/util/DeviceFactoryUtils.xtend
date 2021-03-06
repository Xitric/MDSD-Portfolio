package org.iot.devicefactory.util

import java.util.ArrayList
import org.eclipse.emf.ecore.EObject
import org.iot.devicefactory.common.Variable
import org.iot.devicefactory.deviceFactory.BaseDevice
import org.iot.devicefactory.deviceFactory.BaseSensor
import org.iot.devicefactory.deviceFactory.Channel
import org.iot.devicefactory.deviceFactory.ChildDevice
import org.iot.devicefactory.deviceFactory.Cloud
import org.iot.devicefactory.deviceFactory.Data
import org.iot.devicefactory.deviceFactory.Deployment
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.Fog
import org.iot.devicefactory.deviceFactory.OverrideSensor
import org.iot.devicefactory.deviceFactory.Sampler
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceLibrary.SensorDefinition
import org.iot.devicefactory.deviceLibrary.SensorInput

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
	
	static def getInputChannel(Device device) {
		device.deviceHierarchy.map[input].findFirst[it !== null]
	}
	
	static def SensorDefinition getDefinition(Sensor sensor) {
		switch sensor {
			BaseSensor: sensor.definition
			OverrideSensor: sensor.parent.definition
		}
	}
	
	static def String getName(Sensor sensor) {
		sensor.definition.name
	}
	
	static def SensorInput getInput(Sensor sensor) {
		sensor.definition.input
	}
	
	static def Sampler getSampler(Sensor sensor) {
		switch sensor {
			BaseSensor: sensor.sampler
			OverrideSensor: sensor.sampler ?: getSampler(sensor.parent)
		}
	}
	
	static def Iterable<Variable> getVariables(Sensor sensor) {
		sensor.definition?.variables ?: emptyList
	}

	static def getBoard(Device device) {
		val top = device.deviceHierarchy.last
		switch top {
			BaseDevice: top.board
			ChildDevice: null
		}
	}
	
	static def Channel getInput(Device device) {
		switch device {
			BaseDevice: device.input
			ChildDevice: device.input ?: getInput(device.parent)
		}
	}

	static def getBaseData(Data data) {
		val allDatas = data.getContainerOfType(Deployment).eContents.flatMap[datas]
		allDatas.findFirst[name == data.name]
	}
	
	static def getDatas(EObject context) {
		switch context {
			Device: context.sensors.flatMap[datas].map[it as Data]
			Fog: context.transformations.flatMap[datas].map[it as Data]
			Cloud: context.transformations.flatMap[datas].map[it as Data]
			default: emptyList
		}
	}
	
	static def fog(Deployment deployment) {
		deployment.fogs.nullOrEmpty ? null : deployment.fogs.get(0)
	}
	
	static def cloud(Deployment deployment) {
		deployment.clouds.nullOrEmpty ? null : deployment.clouds.get(0)
	}
}
