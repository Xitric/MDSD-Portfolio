package org.iot.devicefactory.tests.typing

import org.iot.devicefactory.typing.ExpressionType
import org.junit.jupiter.api.Test

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.junit.jupiter.api.Assertions.*

class ExpressionTypeTest {
	
	private def assertNotEqualAny(ExpressionType a, ExpressionType... others) {
		for (ExpressionType other : others) {
			a.assertNotEquals(other)
		}
	}
	
	@Test def void testEqualSameType() {
		INTEGER.assertEquals(INTEGER)
		DOUBLE.assertEquals(DOUBLE)
		BOOLEAN.assertEquals(BOOLEAN)
		STRING.assertEquals(STRING)
		VOID.assertEquals(VOID)
	}
	
	@Test def void testEqualDifferentType() {
		INTEGER.assertEquals(DOUBLE)
		
		INTEGER.assertNotEqualAny(BOOLEAN, STRING, VOID)
		DOUBLE.assertNotEqualAny(INTEGER, BOOLEAN, STRING, VOID)
		BOOLEAN.assertNotEqualAny(INTEGER, DOUBLE, STRING, VOID)
		STRING.assertNotEqualAny(INTEGER, DOUBLE, BOOLEAN, VOID)
		VOID.assertNotEqualAny(INTEGER, DOUBLE, BOOLEAN, STRING)
	}
	
	@Test def void testTupleSameType() {
		TUPLE(INTEGER, STRING)
			.assertEquals(TUPLE(INTEGER, STRING))
		
		TUPLE(INTEGER, STRING)
			.assertEquals(TUPLE(DOUBLE, STRING))
		
		TUPLE(INTEGER, DOUBLE)
			.assertEquals(TUPLE(DOUBLE, DOUBLE))
	}
	
	@Test def void testTupleDifferentType() {
		TUPLE(INTEGER, STRING)
			.assertNotEquals(TUPLE(INTEGER, BOOLEAN))
		
		TUPLE(INTEGER, STRING)
			.assertNotEquals(TUPLE(STRING, INTEGER))
		
		TUPLE(DOUBLE, DOUBLE)
			.assertNotEquals(TUPLE(INTEGER, DOUBLE))
	}
	
	@Test def void testTupleDifferentLengths() {
		TUPLE(INTEGER, STRING)
			.assertNotEquals(TUPLE(INTEGER, STRING, STRING))
		
		TUPLE(INTEGER, STRING, STRING)
			.assertNotEquals(TUPLE(INTEGER, STRING))
	}
}