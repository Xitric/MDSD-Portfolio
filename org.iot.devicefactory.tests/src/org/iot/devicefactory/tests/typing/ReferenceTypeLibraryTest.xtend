package org.iot.devicefactory.tests.typing

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.Add
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.deviceLibrary.Library
import org.iot.devicefactory.tests.DeviceLibraryInjectorProvider
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(DeviceLibraryInjectorProvider)
class ReferenceTypeLibraryTest {
	
	@Inject extension ParseHelper<Library>
	@Inject extension ExpressionTypeChecker
	
	@Test def void testReferenceUndefined() {
		'''
		define board BoardA
			sensor barometer pin(12) as a
				preprocess filter[b]
		'''.parse.boards.get(0).sensors.get(0).preprocess => [
			(pipeline as Filter).expression.typeOf.assertSame(VOID)
		]
	}
	
	//TODO
	@Test def void testReferenceDefined() {
		'''
		define board BoardA
			sensor barometer pin(12) as a
				preprocess filter[a]
		'''.parse.boards.get(0).sensors.get(0).preprocess => [
			(pipeline as Filter).expression.typeOf.assertSame(INTEGER)
		]
	}
	
	@Test def void testReferenceTuple() {
		'''
		define board BoardA
			sensor barometer pin(12, 13) as (a, b)
				preprocess filter[a + b]
		'''.parse.boards.get(0).sensors.get(0).preprocess => [
			((pipeline as Filter).expression as Add).left.typeOf.assertSame(INTEGER)
			((pipeline as Filter).expression as Add).right.typeOf.assertSame(INTEGER)
		]
	}
	
	@Test def void testReferenceInherited() {
		'''
		define board BoardA
			sensor barometer pin(12) as a
		define board BoardB includes BoardA
			override sensor barometer
				preprocess filter[a]
		'''.parse.boards.get(1).sensors.get(0).preprocess => [
			(pipeline as Filter).expression.typeOf.assertSame(INTEGER)
		]
	}
	
	@Test def void testReferencePreprocessInherited() {
		'''
		define board BoardA
			sensor barometer pin(12) as a
				preprocess map[a + "" => a]
		define board BoardB includes BoardA
			override sensor barometer
				preprocess filter[a]
		'''.parse.boards.get(1).sensors.get(0).preprocess => [
			(pipeline as Filter).expression.typeOf.assertSame(STRING)
		]
	}
	
	@Test def void testReferenceRedeclared() {
		'''
		define board BoardA
			sensor barometer pin(12) as a
		define board BoardB includes BoardA
			override sensor barometer
				preprocess map[a + "" => a]
		define board BoardC includes BoardB
			override sensor barometer
				preprocess filter[a]
		'''.parse.boards.get(2).sensors.get(0).preprocess => [
			(pipeline as Filter).expression.typeOf.assertSame(STRING)
		]
	}
	
	@Test def void testReferenceTupleRedeclared() {
		'''
		define board BoardA
			sensor barometer pin(12, 13) as (a, b)
		define board BoardB includes BoardA
			override sensor barometer
				preprocess map[a > 0 => b]
		define board BoardC includes BoardB
			override sensor barometer
				preprocess filter[a + b]
		'''.parse.boards.get(2).sensors.get(0).preprocess => [
			((pipeline as Filter).expression as Add).left.typeOf.assertSame(VOID)
			((pipeline as Filter).expression as Add).right.typeOf.assertSame(BOOLEAN)
		]
	}
}
