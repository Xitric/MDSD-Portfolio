package org.iot.devicefactory.generator.python.device

import com.google.inject.Inject
import java.util.ArrayList
import java.util.HashSet
import java.util.Set
import org.eclipse.xtext.resource.IEObjectDescription
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.deviceFactory.Device
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.generator.python.GeneratorEnvironment
import org.iot.devicefactory.generator.python.GeneratorUtils
import org.iot.devicefactory.scoping.DeviceLibraryScopeProvider

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*
import static extension org.iot.devicefactory.generator.python.ImportGenerator.*
import static extension org.iot.devicefactory.util.DeviceFactoryUtils.*
import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*

class BoardGenerator {

	@Inject DeviceLibraryScopeProvider deviceLibraryScopeProvider
	@Inject extension PipelineGenerator
	@Inject extension GeneratorUtils

	def String compile(Device device, GeneratorEnvironment env) {
		val boardClasses = device.board.compileClass(device, new HashSet<Board>(), env)

		'''
			«env.compileImports»
			
			«boardClasses»
		'''
	}

	private def String compileClass(Board board, Device device, Set<Board> visited, GeneratorEnvironment env) {
		if (visited.contains(board)) return null
		visited.add(board)
		
		'''
			«FOR parent : board.parents»«parent.compileClass(device, visited, env)»«ENDFOR»
			class «board.name.asClass»:
			
				«board.compileConstructor(device, env)»
				«board.compileSensors(device, env)»
		'''
	}

	private def String compileConstructor(Board board, Device device, GeneratorEnvironment env) {
		val usedSensors = board.sensors.filter(BaseSensorDefinition).filter[device.usesSensor(it.name)]
		
		val parentArgs = '''«FOR parent : board.parents», «parent.name.asModule»«ENDFOR»'''
		val driverArgs = '''«FOR sensor : usedSensors», «sensor.name.asModule»«ENDFOR»'''
		
		'''
			def __init__(self«parentArgs»«driverArgs»):
				«FOR parent : board.parents»
					self.«parent.name.asInstance» = «parent.name.asModule»
				«ENDFOR»
				«FOR sensor : usedSensors»
				self.«sensor.name.asInstance»_driver = «sensor.name.asModule»
				«ENDFOR»
			
		'''
	}

	private def String compileSensors(Board board, Device device, GeneratorEnvironment env) {
		val parentSensorScope = deviceLibraryScopeProvider.getScope(board, Literals.OVERRIDE_SENSOR_DEFINITION__PARENT)
		val qualifiedParentScope = parentSensorScope.allElements.filter [
			name.segmentCount > 1 && device.usesSensor(name.lastSegment)
		]
		val overrideSensors = board.sensors.filter(OverrideSensorDefinition)

		// Qualified names of the sensors that this board overrides
		// This also removes ambiguities in the parent scope
		val overriddenSensors = qualifiedParentScope.filter [ parentSensor |
			overrideSensors.exists[it.parent.URI == parentSensor.EObjectURI]
		]

		// Sensors that are not overridden in this board
		val passThroughSensors = qualifiedParentScope.filter [ parentSensor |
			! board.sensors.exists[name == parentSensor.name.lastSegment]
		]
		val uniquePassthroughSensors = new ArrayList<IEObjectDescription>()
		for (IEObjectDescription desc: passThroughSensors) {
			if (uniquePassthroughSensors.findFirst[EObjectURI == desc.EObjectURI] === null) {
				uniquePassthroughSensors.add(desc)
			}
		}

		'''
			«FOR sensor : board.sensors.filter[device.usesSensor(name)]»
				def sample_«sensor.name.asModule»(self):
					«sensor.compileSensorSampling(overriddenSensors.findFirst[name.lastSegment == sensor.name]?.name?.firstSegment, env)»
					«IF sensor.preprocess === null»
						return _data
					«ELSE»
						«sensor.preprocess.pipeline.compilePipeline(env)»
						«sensor.preprocess.pipeline.compilePipelineComposition(env)»
						return _pipeline.handle(_data)
					«ENDIF»
				
			«ENDFOR»
			
			«FOR sensor : uniquePassthroughSensors»
				def sample_«sensor.name.lastSegment.asModule»(self):
					return self.«sensor.name.firstSegment.asInstance».sample_«sensor.name.lastSegment.asModule»()
				
			«ENDFOR»
		'''
	}

	private def dispatch String compileSensorSampling(BaseSensorDefinition sensor, String parentBoard,
		GeneratorEnvironment env) {
		'''_data = self.«sensor.name.asInstance»_driver.sample()'''
	}

	private def dispatch String compileSensorSampling(OverrideSensorDefinition sensor, String parentBoard,
		GeneratorEnvironment env) {
		'''_data = self.«parentBoard.asInstance».sample_«sensor.name.asModule»()'''
	}

	private def String compilePipelineComposition(Pipeline pipeline, GeneratorEnvironment env) {
		env.useImport("pipeline", "Pipeline")

		val sink = '''
		type('ReturnSink', (object,), {
			"handle": lambda data: data,
			"next": None
		})'''

		'''
			_pipeline = Pipeline(
				«pipeline.compilePipelineCompositionStep(sink, env)»
			)
		'''
	}

	private def String compilePipelineCompositionStep(Pipeline pipeline, String sink, GeneratorEnvironment env) {
		'''
			«pipeline.interceptorName»(
				«pipeline.next === null ? sink : pipeline.next.compilePipelineCompositionStep(sink, env)»
			)
		'''
	}
}
