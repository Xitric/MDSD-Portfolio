package org.iot.devicefactory.generator.python.device

import com.google.inject.Inject
import org.iot.devicefactory.deviceFactory.FrequencySampler
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.generator.python.GeneratorEnvironment
import org.iot.devicefactory.generator.python.GeneratorUtils

import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*
import static extension org.iot.devicefactory.generator.python.ImportGenerator.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class SensorGenerator {

	@Inject extension PipelineGenerator
	@Inject extension GeneratorUtils

	def String compile(Sensor sensor, GeneratorEnvironment env) {
		val classDef = sensor.compileClass(env)
		if (sensor.isFrequency) {
			env.useLibFile("thread.py")
		}

		'''
			«env.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(Sensor sensor, GeneratorEnvironment env) {
		'''
			class «sensor.name.asClass»:
				
				«sensor.compileConstructor(env)»
				«sensor.compileTimerLoop(env)»
				«sensor.compileSignalHandler(env)»
				«compileInjectionMethods()»
			
			«sensor.compileInterceptors(env)»
		'''
	}

	private def String compileConstructor(Sensor sensor, GeneratorEnvironment env) {
		'''
			def __init__(self, board):
				self.board = board
				self.datas = {}
				«IF sensor.isFrequency»
					self.thread = «env.useImport("thread")».Thread(self.__timer, "Thread«sensor.name.asClass»")
					self.thread.start()
				«ENDIF»
				
		'''
	}

	private def String compileTimerLoop(Sensor sensor, GeneratorEnvironment env) {
		'''
			«IF sensor.isFrequency»
				def __timer(self, thread: thread.Thread):
					while thread.active:
						«env.useImport("utime")».sleep(«(sensor.sampler as FrequencySampler).delay»)
						«sensor.compileSensorSampling(env)»
				
			«ENDIF»
		'''
	}

	private def String compileSignalHandler(Sensor sensor, GeneratorEnvironment env) {
		'''
			def signal(self, command: str):
				«IF sensor.isFrequency»
					if command == "kill":
						self.thread.interrupt()
				«ENDIF»
				«IF sensor.isSignal»
					«IF sensor.isFrequency»el«ENDIF»if command == "signal":
						«sensor.compileSensorSampling(env)»
				«ENDIF»
			
		'''
	}

	private def String compileSensorSampling(Sensor sensor, GeneratorEnvironment env) {
		'''
			_data = self.board.sample_«sensor.name.asModule»()
			for data in self.datas:
				for pipeline in self.datas[data]:
					pipeline.handle(_data)
		'''
	}

	private def String compileInjectionMethods() {
		'''
			def add_pipeline(self, identifier: str, pipeline):
				if not identifier in self.datas:
					self.datas[identifier] = [pipeline]
				else:
					self.datas[identifier].append(pipeline)
			
		'''
	}

	private def String compileInterceptors(Sensor sensor, GeneratorEnvironment env) {
		'''
			«FOR data : sensor.sensorDatas»
				«FOR out : data.outputs»
					«IF out.pipeline !== null»
						«out.pipeline.compilePipeline(env)»
					«ENDIF»
				«ENDFOR»
			«ENDFOR»
		'''
	}
}
