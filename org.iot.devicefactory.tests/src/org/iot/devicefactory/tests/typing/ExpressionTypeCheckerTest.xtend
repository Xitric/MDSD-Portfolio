package org.iot.devicefactory.tests.typing

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.iot.devicefactory.common.CommonFactory
import org.iot.devicefactory.common.Expression
import org.iot.devicefactory.tests.CommonInjectorProvider
import org.iot.devicefactory.typing.ExpressionType
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.iot.devicefactory.typing.TupleExpressionType
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(CommonInjectorProvider)
class ExpressionTypeCheckerTest {
	
	@Inject extension ExpressionTypeChecker
	
	private def assertExpressionType(Expression obj, ExpressionType type) {
		if (type instanceof TupleExpressionType) {
			type.assertEquals(obj.typeOf)
		} else {
			type.assertSame(obj.typeOf)
		}
	}
	
	private def makeInteger() {
		CommonFactory.eINSTANCE.createNumberLiteral => [
			value = "64"
		]
	}
	
	private def makeDouble() {
		CommonFactory.eINSTANCE.createNumberLiteral => [
			value = "64.128"
		]
	}
	
	private def makeBoolean() {
		CommonFactory.eINSTANCE.createBooleanLiteral => [
			value = true
		]
	}
	
	private def makeString() {
		CommonFactory.eINSTANCE.createStringLiteral => [
			value = "Hello, world!"
		]
	}
	
	@Test def void testNumberTypes() {
		INTEGER.isNumberType.assertTrue
		DOUBLE.isNumberType.assertTrue
		
		BOOLEAN.isNumberType.assertFalse
		STRING.isNumberType.assertFalse
		TUPLE(INTEGER).isNumberType.assertFalse
	}
	
	@Test def void testEvaluateNumeralTypes() {
		INTEGER.assertSame(evaluateNumeralTypes(INTEGER, INTEGER))
		DOUBLE.assertSame(evaluateNumeralTypes(INTEGER, DOUBLE))
		DOUBLE.assertSame(evaluateNumeralTypes(DOUBLE, INTEGER))
		
		INTEGER.assertSame(evaluateNumeralTypes(STRING, DOUBLE))
		INTEGER.assertSame(evaluateNumeralTypes(DOUBLE, STRING))
		INTEGER.assertSame(evaluateNumeralTypes(BOOLEAN, STRING))
	}
	
	@Test def void testEvaluateTupleTypes() {
		evaluateTupleTypes(
			TUPLE(STRING, BOOLEAN, INTEGER) as TupleExpressionType,
			TUPLE(STRING, BOOLEAN, INTEGER) as TupleExpressionType
		).assertEquals(TUPLE(STRING, BOOLEAN, INTEGER))
		
		
		evaluateTupleTypes(
			TUPLE(DOUBLE, INTEGER) as TupleExpressionType,
			TUPLE(INTEGER, DOUBLE) as TupleExpressionType
		).assertEquals(TUPLE(DOUBLE, DOUBLE))
		
		
		evaluateTupleTypes(
			TUPLE(INTEGER, STRING) as TupleExpressionType,
			TUPLE(DOUBLE) as TupleExpressionType
		).assertEquals(TUPLE(DOUBLE, STRING))
		
		evaluateTupleTypes(
			TUPLE(BOOLEAN, STRING) as TupleExpressionType,
			TUPLE(STRING, DOUBLE) as TupleExpressionType
		).assertEquals(TUPLE(BOOLEAN, STRING))
	}
	
	@Test def void testEvaluateTypes() {
		INTEGER.assertSame(evaluateTypes(INTEGER, INTEGER))
		DOUBLE.assertSame(evaluateTypes(INTEGER, DOUBLE))
		
		evaluateTypes(
			TUPLE(INTEGER, STRING),
			TUPLE(DOUBLE)
		).assertEquals(TUPLE(DOUBLE, STRING))
		
		evaluateTypes(
			STRING,
			TUPLE(BOOLEAN, DOUBLE)
		).assertSame(STRING)
		
		evaluateTypes(
			TUPLE(BOOLEAN, INTEGER),
			DOUBLE
		).assertEquals(TUPLE(BOOLEAN, INTEGER))
	}
	
	@Test def void testNumberLiteral() {
		assertExpressionType(
			makeInteger,
			INTEGER
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createNumberLiteral => [
				value = "0x5f"
			],
			INTEGER
		)
		
		assertExpressionType(
			makeDouble,
			DOUBLE
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createNumberLiteral => [
				value = "64e-3"
			],
			DOUBLE
		)
	}
	
	@Test def void testBooleanLiteral() {
		assertExpressionType(
			makeBoolean,
			BOOLEAN
		)
	}
	
	@Test def void testStringLiteral() {
		assertExpressionType(
			makeString,
			STRING
		)
	}
	
	//TODO: Test reference type
	
	@Test def void testTuple() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createTuple => [
				values.addAll(#[makeString, makeDouble])
			],
			TUPLE(STRING, DOUBLE)
		)
	}
	
	@Test def void testParentheses() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createParentheses => [
				expression = makeString
			],
			STRING
		)
	}
	
	@Test def void testExponent() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createExponent => [
				base = makeInteger
				power = makeInteger
			],
			DOUBLE
		)
	}
	
	@Test def void testNegation() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createNegation => [
				value = makeDouble
			],
			DOUBLE
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createNegation => [
				value = makeString
			],
			INTEGER
		)
	}
	
	@Test def void testMul() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createMul => [
				left = makeInteger
				right = makeInteger
			],
			INTEGER
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createMul => [
				left = makeInteger
				right = makeDouble
			],
			DOUBLE
		)
	}
	
	@Test def void testAdd() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createAdd => [
				left = makeInteger
				right = makeInteger
			],
			INTEGER
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createAdd => [
				left = makeDouble
				right = makeInteger
			],
			DOUBLE
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createAdd => [
				left = makeInteger
				right = makeString
			],
			STRING
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createAdd => [
				left = makeString
				right = makeBoolean
			],
			STRING
		)
	}
	
	@Test def void testConditional() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createConditional => [
				condition = makeBoolean
				first = makeInteger
				second = makeInteger
			],
			INTEGER
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createConditional => [
				condition = makeBoolean
				first = makeInteger
				second = makeDouble
			],
			DOUBLE
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createConditional => [
				condition = makeBoolean
				first = makeString
				second = makeBoolean
			],
			STRING
		)
		
		assertExpressionType(
			CommonFactory.eINSTANCE.createConditional => [
				condition = makeBoolean
				first = makeDouble
				second = makeBoolean
			],
			DOUBLE
		)
	}
	
	@Test def void testAnd() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createAnd => [
				left = makeBoolean
				right = makeBoolean
			],
			BOOLEAN
		)
	}
	
	@Test def void testGreaterThan() {
		assertExpressionType(
			CommonFactory.eINSTANCE.createGreaterThan => [
				left = makeInteger
				right = makeDouble
			],
			BOOLEAN
		)
	}
	
	@Test def void testNull() {
		assertExpressionType(null, VOID)
	}
}