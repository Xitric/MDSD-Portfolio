package org.iot.devicefactory.generator.python.device

import com.google.inject.Inject
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Max
import org.iot.devicefactory.common.Mean
import org.iot.devicefactory.common.Median
import org.iot.devicefactory.common.Min
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.StDev
import org.iot.devicefactory.common.Var
import org.iot.devicefactory.common.Window
import org.iot.devicefactory.deviceLibrary.BaseSensorDefinition
import org.iot.devicefactory.deviceLibrary.Board
import org.iot.devicefactory.deviceLibrary.DeviceLibraryPackage.Literals
import org.iot.devicefactory.deviceLibrary.OverrideSensorDefinition
import org.iot.devicefactory.generator.python.ExpressionGenerator
import org.iot.devicefactory.generator.python.GeneratorEnvironment
import org.iot.devicefactory.scoping.DeviceLibraryScopeProvider
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.iot.devicefactory.typing.TupleExpressionType

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*
import static extension org.iot.devicefactory.generator.python.ImportGenerator.*
import static extension org.iot.devicefactory.util.DeviceLibraryUtils.*

class BoardGenerator {

	@Inject DeviceLibraryScopeProvider deviceLibraryScopeProvider
	@Inject extension ExpressionGenerator
	@Inject extension ExpressionTypeChecker

	def String compile(Board board, GeneratorEnvironment env) {
		val boardClasses = board.compileClass(env)

		'''
			«env.compileImports»
			
			«boardClasses»
		'''
	}

	private def String compileClass(Board board, GeneratorEnvironment env) {
		'''
			«FOR parent : board.parents»«parent.compileClass(env)»«ENDFOR»
			class «board.name.asClass»:
			
				«board.compileConstructor(env)»
				«board.compileSensors(env)»
		'''
	}

	private def String compileConstructor(Board board, GeneratorEnvironment env) {
		val parentArgs = '''«FOR parent : board.parents», «parent.name.asModule»«ENDFOR»'''
		val driverArgs = '''«FOR sensor : board.sensors.filter(BaseSensorDefinition)», «sensor.name.asModule»«ENDFOR»'''
		
		'''
			def __init__(self«parentArgs»«driverArgs»):
				«FOR parent : board.parents»
					self.«parent.name.asInstance» = «parent.name.asModule»
				«ENDFOR»
				«FOR sensor : board.sensors.filter(BaseSensorDefinition)»
				self.«sensor.name.asInstance»_driver = «sensor.name.asModule»
				«ENDFOR»
			
		'''
	}

	private def String compileSensors(Board board, GeneratorEnvironment env) {
		val parentSensorScope = deviceLibraryScopeProvider.getScope(board, Literals.OVERRIDE_SENSOR_DEFINITION__PARENT)
		val qualifiedParentScope = parentSensorScope.allElements.filter [
			name.segmentCount > 1
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

		'''
			«FOR sensor : board.sensors»
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
			
			«FOR sensor : passThroughSensors»
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

	private def String compilePipeline(Pipeline pipeline, GeneratorEnvironment env) {
		'''
			«pipeline.compilePipelineOperation(env)»
			«IF pipeline.next !== null»
				«pipeline.next.compilePipeline(env)»
			«ENDIF»
		'''
	}

	private def dispatch String compilePipelineOperation(Filter filter, GeneratorEnvironment env) {
		env.useLibFile("pipeline.py")
		'''
			class «filter.interceptorName»(«env.useImport("pipeline", "Interceptor")»):
				def handle(self, _tuple):
					_should_continue = «filter.expression.compileExp»
					if _should_continue:
						return self.next.handle(_tuple)
			
		'''
	}

	private def dispatch String compilePipelineOperation(Map map, GeneratorEnvironment env) {
		env.useImport("collections", "namedtuple")
		env.useLibFile("pipeline.py")
		'''
			class «map.interceptorName»(«env.useImport("pipeline", "Interceptor")»):
				def handle(self, _tuple):
					_Container = «map.output.compileNamedTuple»
					_newValue = «map.expression.compileExp»
					«IF map.expression.typeOf instanceof TupleExpressionType»
						return self.next.handle(_Container(*_newValue))
					«ELSE»
						return self.next.handle(_Container(_newValue))
					«ENDIF»
			
		'''
	}

	private def dispatch String compilePipelineOperation(Window window, GeneratorEnvironment env) {
		env.useImport("collections", "namedtuple")
		env.useLibFile("pipeline.py")
		'''
			class «window.interceptorName»(«env.useImport("pipeline", "Interceptor")»):
				def __init__(self, next: Interceptor):
					super().__init__(next)
					self._buffer = []
				
				def handle(self, _tuple):
					self._buffer.append(_tuple)
					if len(self._buffer) == «window.width»:
						def _execute(_values):
							«window.execute.compileExecute»
						_result_list = [_execute([value for value in map(lambda v: v[i], self._buffer)]) for i in range(len(_tuple))]
						_Container = namedtuple("tuple", " ".join(_tuple._fields))
						_result = _Container(*_result_list)
						self._buffer = []
						return self.next.handle(_tuple(_result))
			
		'''
	}

	private def dispatch String compileExecute(Mean execute) {
		'''
			return sum(_values) / len(_values)
		'''
	}

	private def dispatch String compileExecute(Median execute) {
		'''
			_values = list(_values)
			_values.sort()
			mid = len(_values) // 2
			if len(_values) % 2 is 0:
				return (_values[mid - 1] + _values[mid]) / 2
			else:
				return _values[mid]
		'''
	}

	private def dispatch String compileExecute(Var execute) {
		'''
			# TODO: Unsupported
			pass
		'''
	}

	private def dispatch String compileExecute(StDev execute) {
		'''
			# TODO: Unsupported
			pass
		'''
	}

	private def dispatch String compileExecute(Min execute) {
		'''
			return min(_values)
		'''
	}

	private def dispatch String compileExecute(Max execute) {
		'''
			return max(_values)
		'''
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
