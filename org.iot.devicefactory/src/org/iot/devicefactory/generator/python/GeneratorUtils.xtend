package org.iot.devicefactory.generator.python

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.VariableDeclaration
import org.iot.devicefactory.common.Window
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.DeviceFactoryPackage.Literals
import org.iot.devicefactory.deviceFactory.FrequencySampler
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorData
import org.iot.devicefactory.deviceFactory.SignalSampler
import org.iot.devicefactory.deviceLibrary.SensorDefinition
import org.iot.devicefactory.scoping.DeviceFactoryScopeProvider

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.util.CommonUtils.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class GeneratorUtils {

	@Inject DeviceFactoryScopeProvider deviceFactoryScopeProvider

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
		
		val dataContainer = pipeline.getContainerOfType(SensorData)
		if (dataContainer !== null) {
			'''«dataContainer.name.asClass»Interceptor«type»«index»'''
		} else {
			'''Interceptor«type»«index»'''
		}
	}

	static def String compileNamedTuple(VariableDeclaration varDecl) {
		'''namedtuple("tuple", "«FOR id : varDecl.variables SEPARATOR " "»«id.name»«ENDFOR»")'''
	}
	
	def boolean usesSensor(Device device, String sensorName) {
		device.allSensors.exists[name == sensorName]
	}
	
	def Iterable<Sensor> allSensors(Device device) {
		val sensorScope = deviceFactoryScopeProvider.getScope(device, Literals.SENSOR)
		return sensorScope.allElements.map[EObjectOrProxy as Sensor]
	}

	def Iterable<SensorData> sensorDatas(Sensor sensor) {
		val dataScope = deviceFactoryScopeProvider.getScope(sensor, Literals.SENSOR_DATA)
		return dataScope.allElements.map[EObjectOrProxy as SensorData]
	}
}
