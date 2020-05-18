package org.iot.devicefactory.typing

import com.google.inject.Inject
import org.iot.devicefactory.common.Add
import org.iot.devicefactory.common.Conditional
import org.iot.devicefactory.common.Div
import org.iot.devicefactory.common.Exponent
import org.iot.devicefactory.common.Expression
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Mul
import org.iot.devicefactory.common.Negation
import org.iot.devicefactory.common.NumberLiteral
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.Reference
import org.iot.devicefactory.common.StringLiteral
import org.iot.devicefactory.common.Sub
import org.iot.devicefactory.common.Tuple
import org.iot.devicefactory.common.Window

import static org.iot.devicefactory.typing.ExpressionType.*

class ExpressionTypeChecker {

	@Inject extension ReferenceTypeProvider
	@Inject extension ContextTypeProvider

	/**
	 * Determines if the provided type is either an integer or a double.
	 */
	def isNumberType(ExpressionType type) {
		return type == DOUBLE
	}

	/**
	 * Find the numeral type to which both type1 and type2 can be assigned. 
	 */
	def evaluateNumeralTypes(ExpressionType type1, ExpressionType type2) {
		if (type1.isNumberType && type2.isNumberType) {
			if (type1 === DOUBLE || type2 === DOUBLE) {
				return DOUBLE
			}
		}
		
		INTEGER
	}
	
	/**
	 * Find the best proposal for a tuple type that is compatible with both
	 * type1 and type2.
	 */
	def ExpressionType evaluateTupleTypes(TupleExpressionType type1, TupleExpressionType type2) {
		val typeCount = Math.max(type1.elements.length, type2.elements.length)
		val ExpressionType[] evaluatedTypes = newArrayOfSize(typeCount)
		
		for (var i = 0; i < typeCount; i++) {
			if(i < type1.elements.length && i < type2.elements.length) {
				val typeA = type1.elements.get(i)
				val typeB = type2.elements.get(i)
				evaluatedTypes.set(i, evaluateTypes(typeA, typeB))
			} else if (i < type1.elements.length) {
				evaluatedTypes.set(i, type1.elements.get(i))
			} else if (i < type2.elements.length) {
				evaluatedTypes.set(i, type2.elements.get(i))
			}
		}
		
		TUPLE(evaluatedTypes)
	}
	
	/**
	 * Find the best proposal for a type that is compatible with both type1 and
	 * type2.
	 */
	def evaluateTypes(ExpressionType type1, ExpressionType type2) {
		if (type1.isNumberType && type2.isNumberType) {
			evaluateNumeralTypes(type1, type2)
		} else if (type1 instanceof TupleExpressionType && type2 instanceof TupleExpressionType) {
			evaluateTupleTypes(type1 as TupleExpressionType, type2 as TupleExpressionType)
		} else {
			type1
		}
	}

	def dispatch ExpressionType typeOf(NumberLiteral exp) {
		val value = exp.value
		switch value {
			case value.startsWith("0x"):
				INTEGER
			case value.contains('.'),
			case value.contains('e'):
				DOUBLE
			default:
				INTEGER
		}
	}

	def dispatch ExpressionType typeOf(StringLiteral exp) {
		STRING
	}

	def dispatch ExpressionType typeOf(Reference exp) {
		if (exp?.variable?.name === null) {
			return VOID
		}
		
		return exp.typeOf(this)
	}

	def dispatch ExpressionType typeOf(Tuple exp) {
		TUPLE(exp.values.map[typeOf])
	}

	def dispatch ExpressionType typeOf(Exponent exp) {
		DOUBLE
	}

	def dispatch ExpressionType typeOf(Negation exp) {
		if (exp.value.typeOf == DOUBLE) {
			DOUBLE
		} else {
			INTEGER
		}
	}

	def dispatch ExpressionType typeOf(Mul exp) {
		evaluateNumeralTypes(exp.left.typeOf, exp.right.typeOf)
	}

	def dispatch ExpressionType typeOf(Div exp) {
		evaluateNumeralTypes(exp.left.typeOf, exp.right.typeOf)
	}

	def dispatch ExpressionType typeOf(Add exp) {
		if (exp.left.typeOf == STRING || exp.right.typeOf == STRING) {
			STRING
		} else {
			evaluateNumeralTypes(exp.left.typeOf, exp.right.typeOf)
		}
	}

	def dispatch ExpressionType typeOf(Sub exp) {
		evaluateNumeralTypes(exp.left.typeOf, exp.right.typeOf)
	}

	def dispatch ExpressionType typeOf(Conditional exp) {
		evaluateTypes(exp.first.typeOf, exp.second.typeOf)
	}

	// Handles all remaining types that default to BOOLEAN
	def dispatch ExpressionType typeOf(Expression exp) {
		BOOLEAN
	}
	
	// Fall back in case of null invocations
	def dispatch ExpressionType typeOf(Void exp) {
		VOID
	}
	
	// Gets the input of a single pipeline operation
	def inputTypeOfPipeline(Pipeline pipeline) {
		val precedingPipeline = pipeline.eContainer
		switch precedingPipeline {
			Pipeline: precedingPipeline.typeOfPipeline
			default: pipeline.getContextType(this)
		}
	}
	
	// Gets the output of a single pipeline operation
	def dispatch ExpressionType typeOfPipeline(Filter filter) {
		filter.inputTypeOfPipeline
	}
	
	def dispatch ExpressionType typeOfPipeline(Map map) {
		map.expression.typeOf
	}
	
	def dispatch ExpressionType typeOfPipeline(Window window) {
		val inputType = window.inputTypeOfPipeline
		switch inputType {
			TupleExpressionType: TUPLE(DOUBLE, inputType.elements.size)
			ExpressionType: DOUBLE
		}
	}
	
	// Gets the output of a complete pipeline
	def outputTypeOfPipeline(Pipeline pipeline) {
		var Pipeline lastTypeChanger = null
		
		var current = pipeline
		while (current !== null) {
			switch current {
				Map, Window: lastTypeChanger = current
			}
			current = current.next
		}
		
		switch lastTypeChanger {
			Map: lastTypeChanger.expression.typeOf
			Window: DOUBLE
			default: VOID
		}
	}
}
