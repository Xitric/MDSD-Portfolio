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
import org.iot.devicefactory.generator.python.ExpressionGenerator
import org.iot.devicefactory.generator.python.GeneratorEnvironment
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.iot.devicefactory.typing.TupleExpressionType

import static extension org.iot.devicefactory.generator.python.GeneratorUtils.*

class PipelineGenerator {

	@Inject extension ExpressionGenerator
	@Inject extension ExpressionTypeChecker

	def String compilePipeline(Pipeline pipeline, GeneratorEnvironment env) {
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
}
