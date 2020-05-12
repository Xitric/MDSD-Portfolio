package org.iot.devicefactory.tests.typing

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.iot.devicefactory.common.Add
import org.iot.devicefactory.common.Filter
import org.iot.devicefactory.common.Map
import org.iot.devicefactory.common.Pipeline
import org.iot.devicefactory.common.Unequal
import org.iot.devicefactory.tests.CommonInjectorProvider
import org.iot.devicefactory.typing.ExpressionTypeChecker
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith

import static org.iot.devicefactory.typing.ExpressionType.*

import static extension org.iot.devicefactory.tests.TestUtil.*
import static extension org.junit.jupiter.api.Assertions.*

@ExtendWith(InjectionExtension)
@InjectWith(CommonInjectorProvider)
class ReferenceTypeCommonTest {
	
	@Inject extension ParseHelper<Pipeline>
	@Inject extension ExpressionTypeChecker
	
	@Test def void testReferenceUndefined() {
		'''
		filter[a].filter[b]
		'''.parse => [
			(get(0) as Filter).expression.typeOf.assertSame(VOID)
			(get(1) as Filter).expression.typeOf.assertSame(VOID)
		]
	}
	
	@Test def void testReferenceFromUndefinedMap() {
		'''
		map[a => b].filter[b]
		'''.parse => [
			(get(1) as Filter).expression.typeOf.assertSame(VOID)
		]
	}
	
	@Test def void testReferenceFromMap() {
		'''
		map[2 => a].filter[a]
		'''.parse => [
			(get(1) as Filter).expression.typeOf.assertSame(INTEGER)
		]
		
		'''
		map[2.8 => a].filter[a]
		'''.parse => [
			(get(1) as Filter).expression.typeOf.assertSame(DOUBLE)
		]
		
		'''
		map["" => a].filter[a]
		'''.parse => [
			(get(1) as Filter).expression.typeOf.assertSame(STRING)
		]
		
		'''
		map[false => a].filter[a]
		'''.parse => [
			(get(1) as Filter).expression.typeOf.assertSame(BOOLEAN)
		]
	}
	
	@Test def void testReferenceTuple() {
		'''
		map[(1, 1.2, "", true) => (a, b, c, d)].filter[a].filter[b].filter[c].filter[d]
		'''.parse => [
			(get(1) as Filter).expression.typeOf.assertSame(INTEGER)
			(get(2) as Filter).expression.typeOf.assertSame(DOUBLE)
			(get(3) as Filter).expression.typeOf.assertSame(STRING)
			(get(4) as Filter).expression.typeOf.assertSame(BOOLEAN)
		]
	}
	
	@Test def void testReferenceChain() {
		'''
		map[1 => a].map[a + "" => b].map[b != "" => c].filter[c]
		'''.parse => [
			((get(1) as Map).expression as Add).left.typeOf.assertSame(INTEGER)
			((get(2) as Map).expression as Unequal).left.typeOf.assertSame(STRING)
			(get(3) as Filter).expression.typeOf.assertSame(BOOLEAN)
		]
	}
	
	@Test def void testReferenceRedefined() {
		'''
		map[1 => a].map[a + "" => a].filter[a]
		'''.parse => [
			((get(1) as Map).expression as Add).left.typeOf.assertSame(INTEGER)
			(get(2) as Filter).expression.typeOf.assertSame(STRING)
		]
	}
	
	@Test def void testReferenceTupleRedefined() {
		'''
		map[(1, "") => (a, b)].map[b => a].filter[b + a].filter[a].filter[b]
		'''.parse => [
			(get(1) as Map).expression.typeOf.assertSame(STRING)
			((get(2) as Filter).expression as Add).left.typeOf.assertSame(VOID)
			((get(2) as Filter).expression as Add).right.typeOf.assertSame(STRING)
			(get(3) as Filter).expression.typeOf.assertSame(STRING)
			(get(4) as Filter).expression.typeOf.assertSame(VOID)
		]
	}
}
