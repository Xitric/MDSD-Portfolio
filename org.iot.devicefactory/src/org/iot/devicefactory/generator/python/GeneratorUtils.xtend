package org.iot.devicefactory.generator.python

import org.eclipse.emf.ecore.EObject
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Window
import org.iot.devicefactory.deviceFactory.FrequencySampler
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorData
import org.iot.devicefactory.deviceFactory.SignalSampler
import org.iot.devicefactory.deviceLibrary.SensorDefinition

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.CommonUtils.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class GeneratorUtils {

	static def String asInstance(String name) {
		'''_«name»'''
	}

	static def String asModule(String name) {
		name.toLowerCase
	}

	static def String asClass(String name) {
		name.toFirstUpper
	}

	static def boolean isFrequency(Sensor sensor) {
		getSampler(sensor) instanceof FrequencySampler
	}

	static def boolean isSignal(Sensor sensor) {
		getSampler(sensor) instanceof SignalSampler
	}

	static def Iterable<SensorData> sensorDatas(Sensor sensor) {
		return sensor.eAllOfType(SensorData)
	}

	static def String interceptorName(Pipeline pipeline) {
		val type = switch (pipeline) {
			Filter: "Filter"
			Map: "Map"
			Window: "Window"
		}

		var EObject sensor = pipeline.getContainerOfType(Sensor) ?: pipeline.getContainerOfType(SensorDefinition)
		val index = sensor.eAllContents.filter [
			it.class == pipeline.class
		].takeWhile [
			it != pipeline
		].size + 1

		'''Interceptor«type»«index»'''
	}

	static def String compileNamedTuple(VariableDeclaration varDecl) {
		'''namedtuple("tuple", "«FOR id : varDecl.variables SEPARATOR " "»«id.name»«ENDFOR»")'''
	}
}
