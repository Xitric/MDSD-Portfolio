package org.iot.devicefactory.generator.python.device

import com.google.inject.Inject
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.generator.python.GeneratorEnvironment
import org.iot.devicefactory.generator.python.GeneratorUtils

import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*
import static extension org.iot.devicefactory.generator.python.ImportGenerator.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class DeviceGenerator {

	@Inject extension GeneratorUtils

	def String compile(Device device, GeneratorEnvironment env) {
		val classDef = device.compileClass(env)
		if (getInput(device) !== null) {
			env.useLibFile("thread.py")
		}

		'''
			«env.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(Device device, GeneratorEnvironment env) {
		'''
			class «device.name.asClass»:
				
				«device.compileConstructor(env)»
				«device.compileSetupMethods(env)»
				«device.compileInputLoop(env)»
				«device.compileRunMethod(env)»
		'''
	}

	private def String compileConstructor(Device device, GeneratorEnvironment env) {
		'''
			def __init__(self):
				self._sensors = {}
				self._output_channels = []
				«IF getInput(device) !== null»
					self._input_channel = None
					self._in_thread = «env.useImport("thread")».Thread(self._input_loop, "ThreadInput")
				«ENDIF»
			
		'''
	}

	private def String compileSetupMethods(Device device, GeneratorEnvironment env) {
		'''
			def add_sensor(self, identifier: str, sensor):
				self._sensors[identifier] = sensor
			
			def add_output_channel(self, channel):
				self._output_channels.append(channel)
			
			«IF getInput(device) !== null»
				def set_input_channel(self, channel):
					self._input_channel = channel
				
			«ENDIF»
		'''
	}

	private def String compileInputLoop(Device device, GeneratorEnvironment env) {
		'''
			«IF getInput(device) !== null»
				def _input_loop(self, thread: thread.Thread):
					while thread.active:
						command = self._input_channel.receive().decode("utf-8")
						print("Received: " + command)
						elements = command.split(":")
						sensor = self._sensors[elements[0]]
						sensor.signal(elements[1])
				
			«ENDIF»
		'''
	}

	private def String compileRunMethod(Device device, GeneratorEnvironment env) {
		val frequencySensors = device.allSensors.filter[isFrequency]

		'''
			def run(self):
				«IF getInput(device) !== null»
					self._in_thread.start()
					
				«ENDIF»
				«env.useImport("thread")».join([
					«IF getInput(device) !== null»
						self._in_thread«IF !frequencySensors.empty»,«ENDIF»
					«ENDIF»
					«FOR sensor : frequencySensors SEPARATOR ","»
						self._sensors["«sensor.name.asModule»"].thread
					«ENDFOR»
				])
		'''
	}
}
