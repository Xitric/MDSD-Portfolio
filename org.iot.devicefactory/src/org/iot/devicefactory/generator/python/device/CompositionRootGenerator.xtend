package org.iot.devicefactory.generator.python.device

import com.google.inject.Inject
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.deviceFactory.Channel
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceFactory.Sensor
import org.iot.devicefactory.deviceFactory.SensorData
import org.iot.devicefactory.deviceFactory.SensorOut
import org.iot.devicefactory.deviceLibrary.I2C
import org.iot.devicefactory.deviceLibrary.Pin
import org.iot.devicefactory.generator.python.GeneratorEnvironment
import org.iot.devicefactory.typing.ExpressionType
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.iot.devicefactory.typing.TupleExpressionType

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*
import static extension org.iot.devicefactory.generator.python.ImportGenerator.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*

class CompositionRootGenerator {

	@Inject extension ExpressionTypeChecker

	def String compile(Device device, GeneratorEnvironment env) {
		val classDef = device.compileClass(env)

		'''
			«env.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(Device device, GeneratorEnvironment env) {
		val sensorProviders = device.compileSensorProviders(env)
		val pipelineProviders = device.compilePipelineProviders(env)
		val deviceProvider = device.compileDeviceProvider(env)

		'''
			class CompositionRoot:
				
				«device.compileConstructor(env)»
				«deviceProvider»
				«device.compileDeviceTypeProvider(env)»
				«sensorProviders»
				«pipelineProviders»
				«device.compileChannelProviders(env)»
				«device.compileDriverProviders(env)»
				«compileMakeChannel(env)»
		'''
	}

	private def String compileConstructor(Device device, GeneratorEnvironment env) {
		env.useImport("ujson")

		'''
			def __init__(self):
				«FOR channel : env.channels»
					self.«channel.name.asInstance» = None
				«ENDFOR»
				
				with open("config.json", "r") as _conf_file:
					self.configuration = ujson.loads("".join(_conf_file.readlines()))
			
		'''
	}

	private def String compileDeviceProvider(Device device, GeneratorEnvironment env) {
		'''
			def «device.providerName»(self):
				«device.name.asInstance» = self.provide_device()
				«FOR sensor : device.sensors»
					«device.name.asInstance».add_sensor("«sensor.name.asModule»", self.«sensor.providerName»())
				«ENDFOR»
				«IF device.input !== null»«device.name.asInstance».set_input_channel(self.«env.useChannel(device.input).providerName»())«ENDIF»
				«FOR channel : env.channels.filter[it != device.input]»
					«device.name.asInstance».add_output_channel(self.«channel.providerName»())
				«ENDFOR»
				return «device.name.asInstance»
			
		'''
	}

	private def String compileDeviceTypeProvider(Device device, GeneratorEnvironment env) {
		'''
			def provide_device(self):
				return «env.useImport(device.name.asModule, device.name.asClass)»()
			
		'''
	}

	private def String compileSensorProviders(Device device, GeneratorEnvironment env) {
		'''
			«FOR sensor : device.sensors»
				def «sensor.providerName»(self):
					«sensor.name.asInstance» = «env.useImport(sensor.name.asModule)».«sensor.name.asClass»(self.provide_driver_«sensor.name»())
					«FOR data : sensor.sensorDatas»
						«FOR out : data.outputs»
							«sensor.name.asInstance».add_pipeline("«data.name.asModule»", self.«out.providerName»())
						«ENDFOR»
					«ENDFOR»
					return «sensor.name.asInstance»
				
			«ENDFOR»
		'''
	}

	private def String compilePipelineProviders(Device device, GeneratorEnvironment env) {
		'''
			«FOR sensor : device.sensors»
				«FOR data : sensor.sensorDatas»
					«FOR out : data.outputs»
						«out.compilePipelineProvider(env)»
						
					«ENDFOR»
				«ENDFOR»
			«ENDFOR»
		'''
	}

	private def String compilePipelineProvider(SensorOut out, GeneratorEnvironment env) {
		env.useImport("pipeline", "Pipeline")

		val sink = '''
		type('Sink', (object,), {
			"handle": lambda data: «out.channel.name.asInstance».send(«out.pipeline.compileDataConversion(env)»),
			"next": None
		})'''

		'''
			def «out.providerName»(self):
				«env.useChannel(out.channel).name.asInstance» = self.«out.channel.providerName»()
				return Pipeline(
					«out.pipeline.compilePipelineComposition(sink, env)»
				)
		'''
	}

	private def String compileDataConversion(Pipeline pipeline, GeneratorEnvironment env) {
		env.useImport("struct")
		
		switch pipeline.outputTypeOfPipeline {
			// TODO: How the hell do we send a tuple ?!
			TupleExpressionType: '''data.encode("utf-8")'''
			case ExpressionType.INTEGER: '''struct.pack("i", data)'''
			case ExpressionType.DOUBLE: '''struct.pack("f", data)'''
			case ExpressionType.BOOLEAN: '''struct.pack("?", data)'''
			case ExpressionType.STRING: '''data.encode("utf-8")'''
			case ExpressionType.VOID:
				throw new IllegalStateException("Encountered VOID type in grammar during code generation")
			default:
				throw new IllegalStateException("Encountered unknown type in grammar during code generation")
		}
	}

	private def String compilePipelineComposition(Pipeline pipeline, String sink, GeneratorEnvironment env) {
		val inner = pipeline.next === null ? sink : pipeline.next.compilePipelineComposition(sink, env)
		val sensorName = pipeline.getContainerOfType(Sensor).name
		val interceptorName = pipeline.interceptorName

		'''
			«env.useImport(sensorName.asModule)».«interceptorName»(
				«inner»
			)
		'''
	}

	private def String compileChannelProviders(Device device, GeneratorEnvironment env) {
		'''
			«FOR channel : env.channels»
				def «channel.providerName»(self):
					if not self.«channel.name.asInstance»:
						self.«channel.name.asInstance» = self.make_channel("«channel.name»")
					return self.«channel.name.asInstance»
				
			«ENDFOR»
		'''
	}

	private def String compileDriverProviders(Device device, GeneratorEnvironment env) {
		'''
			«FOR sensor : device.sensors»
				«sensor.input.compileDriverProvider(sensor.name, env)»
				
			«ENDFOR»
		'''
	}

	private dispatch def String compileDriverProvider(Pin pin, String name, GeneratorEnvironment env) {
		env.useImport("collections", "namedtuple")
		
		'''
			def provide_driver_«name»(self):
				_Container = «pin.variables.compileNamedTuple»
				return «env.useImport("adc_driver", "ADCDriver")»(_Container, «FOR num : pin.pins SEPARATOR ", "»«num»«ENDFOR»)
		'''
	}

	private dispatch def String compileDriverProvider(I2C i2c, String name, GeneratorEnvironment env) {
		'''
			def provide_driver_«name»(self):
				# Method stub, should be overridden by client
				pass
		'''
	}

	private def String compileMakeChannel(GeneratorEnvironment env) {
		env.useImport("communication", "Serial")
		env.useImport("communication", "Wifi")

		'''
			def make_channel(self, identifier: str):
				if self.configuration[identifier]["type"] == "serial":
					return Serial(self.configuration["serial"]["baud"],
								  self.configuration["serial"]["databits"],
								  self.configuration["serial"]["paritybits"],
								  self.configuration["serial"]["stopbit"])
				
				elif self.configuration[identifier]["type"] == "wifi":
					return Wifi(self.configuration[identifier]["lane"], 
								self.configuration["wifi"]["ssid"],
								self.configuration["wifi"]["password"])
		'''
	}

	/*
	 * Composition-specific utility extension methods
	 */
	private def String providerName(Device device) {
		'''provide_«device.name.asModule»'''
	}

	private def String providerName(Sensor sensor) {
		'''provide_sensor_«sensor.name.asModule»'''
	}

	private def String providerName(Channel channel) {
		'''provide_channel_«channel.name.asModule»'''
	}

	private def String providerName(SensorOut out) {
		val sensor = out.getContainerOfType(Sensor)
		val data = out.getContainerOfType(SensorData)
		val index = data.outputs.takeWhile [
			it != out
		].size + 1

		'''provide_pipeline_«sensor.name.asModule»_«data.name.asModule»_«index»'''
	}
}
